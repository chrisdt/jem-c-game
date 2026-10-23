<?php
declare(strict_types=1);
require __DIR__.'/../wordpress/sunny-scout-scores/score-rules.php';
define('SUNNY_SCOUT_LIBRARY_ONLY',true);
require __DIR__.'/../server/leaderboard.php';
function check(bool $ok,string $message): void { if (!$ok) throw new RuntimeException($message); }
$rules = new Sunny_Scout_Score_Rules();
$state = Sunny_Scout_Score_Rules::freshState();
check(Sunny_Scout_Score_Rules::QUESTS === ScoutScores::QUESTS && Sunny_Scout_Score_Rules::CAMPAIGN === ScoutScores::CAMPAIGN,'Plugin/client campaign differs');
function requestScore(string $method,array $body,int $now): array {
    global $rules,$state;
    return $rules->request($state,$method,$body,$now,'test');
}
function start(int $now): string {
    [$code,$reply]=requestScore('POST',['action'=>'start','campaign'=>Sunny_Scout_Score_Rules::CAMPAIGN],$now);
    check($code===200 && preg_match('/\A[a-f0-9]{48}\z/',$reply['token'])===1,'Invalid start');
    return $reply['token'];
}
function finish(string $token,int $now): array {
    return requestScore('POST',['action'=>'complete','token'=>$token,'quests'=>Sunny_Scout_Score_Rules::QUESTS,'enemies'=>3,'recoveries'=>1],$now);
}
[$code,$reply]=requestScore('GET',[],1000);
check($code===200 && $reply['scores']===[],'Fresh board is not empty');
$token=start(1000);
check(finish($token,2000)[0]===422,'Too-short time accepted');
$bad=['action'=>'complete','token'=>$token,'quests'=>array_slice(Sunny_Scout_Score_Rules::QUESTS,0,13),'enemies'=>1,'recoveries'=>0];
check(requestScore('POST',$bad,100000)[0]===422,'Partial quest list accepted');
[$code,$completed]=finish($token,100000);
check($code===200 && $completed['result']['duration_ms']===99000,'Server time incorrect');
check(finish($token,200000)[1]===$completed,'Repeated finish changes time');
check(requestScore('POST',['action'=>'submit','token'=>$token,'nickname'=>'<script>'],200000)[0]===422,'Unsafe nickname accepted');
[$code,$posted]=requestScore('POST',['action'=>'submit','token'=>$token,'nickname'=>'Pilot'],200000);
check($code===200 && $posted['rank']===1,'Score not ranked');
check(requestScore('POST',['action'=>'submit','token'=>$token,'nickname'=>'Other'],210000)[1]['nickname']==='Pilot','Duplicate post changes nickname');
$slow=start(300000);finish($slow,450000);
requestScore('POST',['action'=>'submit','token'=>$slow,'nickname'=>'PILOT'],460000);
check(requestScore('GET',[],460000)[1]['scores'][0]['duration_ms']===99000,'Slower duplicate replaced best');
$fast=start(500000);finish($fast,570000);
requestScore('POST',['action'=>'submit','token'=>$fast,'nickname'=>'pilot'],580000);
$board=requestScore('GET',[],580000)[1];
check(count($board['scores'])===1 && $board['scores'][0]['duration_ms']===70000,'Faster duplicate missing');
check(array_keys($board)===['campaign','scores'] && !str_contains(json_encode($board),$token),'Public board leaks private state');
check(requestScore('POST',['action'=>'submit','token'=>str_repeat('0',48),'nickname'=>'Pilot'],580000)[0]===410,'Unknown token accepted');
check(requestScore('POST',['action'=>'start','campaign'=>'other'],580000)[0]===409,'Wrong campaign accepted');
$open=start(600000);
check(requestScore('POST',['action'=>'submit','token'=>$open,'nickname'=>'Pilot'],610000)[0]===409,'Unfinished run posted');
check(finish($open,600000+6*3600000+1)[0]===410,'Old token did not expire');
echo "PASS: plugin campaign, server clock, quests, nickname validation, frozen finishes, idempotent posts, best-time ranking, privacy and expiry\n";
