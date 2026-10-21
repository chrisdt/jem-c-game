<?php
declare(strict_types=1);
define('SUNNY_SCOUT_LIBRARY_ONLY', true);
require __DIR__.'/../server/leaderboard.php';
function check(bool $ok, string $message): void { if (!$ok) throw new RuntimeException($message); }
$dir = sys_get_temp_dir().'/scout-scores-'.bin2hex(random_bytes(6));
$service = new ScoutScores($dir);
function callScore(string $action, array $extra, int $now): array {
    global $service;
    return $service->request('POST',['action'=>$action]+$extra,$now,'local-test');
}
function startScore(int $now): string {
    [$code,$reply] = callScore('start',['campaign'=>ScoutScores::CAMPAIGN],$now);
    check($code===200 && strlen($reply['token'])===48,'Run token missing'); return $reply['token'];
}
function finishScore(string $token, int $now): array { return callScore('complete',['token'=>$token,'quests'=>ScoutScores::QUESTS,'enemies'=>7,'recoveries'=>1],$now); }
try {
    [$code,$reply] = $service->request('GET',[],1000,'local-test');
    check($code===200 && $reply['scores']===[],'Fresh board not empty');
    $token = startScore(1000);
    [$code] = callScore('complete',['token'=>$token,'quests'=>array_slice(ScoutScores::QUESTS,0,13),'enemies'=>1,'recoveries'=>0],100000);
    check($code===422,'Partial run accepted');
    [$code] = finishScore($token,2000); check($code===422,'Impossible instant finish accepted');
    [$code,$reply] = finishScore($token,100000); check($code===200 && $reply['result']['duration_ms']===99000,'Server clock not used');
    [$code,$again] = finishScore($token,140000); check($again===$reply,'Typing/retrying changed stopped time');
    [$code] = callScore('submit',['token'=>$token,'nickname'=>'<script>'],150000); check($code===422,'Unsafe nickname accepted');
    [$code,$reply] = callScore('submit',['token'=>$token,'nickname'=>'Sunny-1'],150000); check($code===200 && $reply['rank']===1,'First score missing');
    [$code,$again] = callScore('submit',['token'=>$token,'nickname'=>'OtherName'],160000); check($again['nickname']==='Sunny-1' && count($again['scores'])===1,'Replay created duplicate');
    $slow = startScore(200000); finishScore($slow,350000);
    callScore('submit',['token'=>$slow,'nickname'=>'SUNNY-1'],360000);
    [$code,$reply] = $service->request('GET',[],370000,'local-test'); check(count($reply['scores'])===1 && $reply['scores'][0]['duration_ms']===99000,'Slower duplicate replaced best');
    $fast = startScore(400000); finishScore($fast,480000);
    callScore('submit',['token'=>$fast,'nickname'=>'sunny-1'],490000);
    [$code,$reply] = $service->request('GET',[],500000,'local-test'); check(count($reply['scores'])===1 && $reply['scores'][0]['duration_ms']===80000,'Improvement not ranked');
    [$code] = callScore('submit',['token'=>'invalid','nickname'=>'Scout'],500000); check($code===410,'Bad token accepted');
    $open = startScore(600000);
    [$code] = callScore('submit',['token'=>$open,'nickname'=>'Scout'],620000); check($code===409,'Unfinished time posted');
    [$code] = callScore('start',['campaign'=>'changed-rules'],630000); check($code===409,'Mixed campaign accepted');
    // Independent workers must not overwrite each other's new run records.
    if (function_exists('pcntl_fork')) {
        $children=[];
        for ($i=0;$i<8;$i++) {
            $pid=pcntl_fork();
            if ($pid===0) { startScore(700000); exit(0); }
            check($pid>0,'Cannot fork scoreboard writer'); $children[]=$pid;
        }
        foreach ($children as $pid) { pcntl_waitpid($pid,$status); check(pcntl_wexitstatus($status)===0,'Concurrent writer failed'); }
        $data=file_get_contents($dir.'/scores.php'); $state=json_decode(substr($data,strpos($data,"\n")+1),true,32,JSON_THROW_ON_ERROR);
        check(count($state['runs'])===12,'Concurrent write lost a run');
    }
    $before=file_get_contents($dir.'/scores.php');
    check(str_starts_with($before,'<?php http_response_code(404); exit; ?>'),'Private state lacks PHP access guard');
    file_put_contents($dir.'/scores.php','broken');
    $blocked=false;
    try { $service->request('GET',[],900000,'local-test'); } catch (Throwable $e) { $blocked=true; }
    check($blocked && file_get_contents($dir.'/scores.php')==='broken','Corrupt file was overwritten');
    echo "PASS: file-backed scores, exact story quests, server clock, frozen finish, nickname validation, one best time, idempotent posting, tokens/campaign, concurrent writes and corrupt-file protection\n";
} finally {
    foreach (glob($dir.'/*')?:[] as $file) unlink($file);
    if (is_dir($dir)) rmdir($dir);
}
