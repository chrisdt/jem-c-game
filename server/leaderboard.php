<?php
/** Sunny Scout's file-backed, same-origin leaderboard. No WordPress/database bootstrap. */
declare(strict_types=1);
final class ScoutScores {
    public const CAMPAIGN = 'three-worlds-story-v1';
    public const QUESTS = ['rowan','bea','otis','mara','iris','finn','frost_pip','frost_nix','frost_tavi','frost_eira','ember_sol','ember_luma','ember_brasa','ember_orin'];
    private const GUARD = "<?php http_response_code(404); exit; ?>\n";
    private string $directory;
    public function __construct(string $directory) { $this->directory = $directory; }
    public function request(string $method, array $body, int $now, string $address): array {
        if ($method !== 'GET' && $method !== 'POST') return [405, ['error'=>'Method not allowed.']];
        if (!is_dir($this->directory) && !@mkdir($this->directory, 0700, true) && !is_dir($this->directory)) throw new RuntimeException('Storage unavailable');
        $lock = @fopen($this->directory.'/scores.lock', 'c');
        if (!$lock || !flock($lock, LOCK_EX)) throw new RuntimeException('Storage busy');
        try {
            $file = $this->directory.'/scores.php';
            $state = ['campaign'=>self::CAMPAIGN, 'runs'=>[], 'scores'=>[], 'rate'=>[]];
            if (is_file($file)) {
                $data = @file_get_contents($file);
                if ($data === false || strlen($data) > 4*1024*1024 || !str_starts_with($data, self::GUARD)) throw new RuntimeException('Invalid storage');
                $state = json_decode(substr($data, strlen(self::GUARD)), true, 32, JSON_THROW_ON_ERROR);
                if (!is_array($state) || ($state['campaign']??'') !== self::CAMPAIGN || !isset($state['runs'],$state['scores'],$state['rate'])) throw new RuntimeException('Invalid storage');
            }
            if ($method === 'GET') return [200, ['campaign'=>self::CAMPAIGN, 'scores'=>$this->publicScores($state['scores'])]];
            foreach ($state['runs'] as $id=>$run) if ($now-$run['started_ms'] > 6*3600*1000) unset($state['runs'][$id]);
            foreach ($state['rate'] as $ip=>$rate) if ($now-$rate['since'] > 600000) unset($state['rate'][$ip]);
            $action = $body['action']??'';
            if ($action === 'start') {
                if (($body['campaign']??'') !== self::CAMPAIGN) return [409,['error'=>'This adventure version uses a different leaderboard. Please refresh the game.']];
                $ip = hash('sha256', $address);
                $rate = $state['rate'][$ip]??['since'=>$now,'count'=>0];
                if ($rate['count'] >= 60 || count($state['runs']) >= 2000 || count($state['rate']) >= 2000) return [429,['error'=>'Too many new runs. Please try again shortly.']];
                $rate['count']++;
                $state['rate'][$ip] = $rate;
                $token = bin2hex(random_bytes(24));
                $state['runs'][$token] = ['started_ms'=>$now, 'complete'=>null, 'submitted'=>false];
                $reply = ['token'=>$token,'campaign'=>self::CAMPAIGN];
            } elseif ($action === 'complete' || $action === 'submit') {
                $token = $body['token']??'';
                if (!is_string($token) || !preg_match('/\A[a-f0-9]{48}\z/D',$token) || !isset($state['runs'][$token])) return [410,['error'=>'This run has expired. Your finish is still shown, but a new run is needed for the shared board.']];
                $run =& $state['runs'][$token];
                if ($action === 'complete') {
                    $quests = $body['quests']??[];
                    $expected = self::QUESTS;
                    if (!is_array($quests) || count($quests)!==14 || count(array_filter($quests,'is_string'))!==14) return [422,['error'=>'Complete all 14 story quests first.']];
                    sort($quests); sort($expected);
                    if ($quests !== $expected) return [422,['error'=>'Complete all 14 story quests first.']];
                    if ($run['complete'] === null) {
                        $duration = $now-$run['started_ms'];
                        if ($duration < 60000 || $duration > 6*3600*1000) return [422,['error'=>'This run could not be verified for the leaderboard.']];
                        foreach (['enemies','recoveries'] as $stat) if (!isset($body[$stat]) || !is_int($body[$stat]) || $body[$stat]<0 || $body[$stat]>10000) return [422,['error'=>'Invalid run statistics.']];
                        $run['complete'] = ['duration_ms'=>$duration,'enemies'=>$body['enemies'],'recoveries'=>$body['recoveries'],'finished_ms'=>$now];
                    }
                    $reply = ['result'=>$run['complete']];
                } else {
                    if ($run['complete'] === null) return [409,['error'=>'Finish the adventure before posting a time.']];
                    $nickname = $body['nickname']??'';
                    if (!is_string($nickname) || !preg_match('/\A[A-Za-z0-9][A-Za-z0-9 _-]{1,15}\z/D',$nickname) || trim($nickname)!==$nickname) return [422,['error'=>'Use a nickname of 2–16 letters, numbers, spaces, - or _.']];
                    if (!$run['submitted']) {
                        $row = $run['complete'] + ['nickname'=>$nickname];
                        $key = strtolower($nickname);
                        if (!isset($state['scores'][$key]) || $row['duration_ms'] < $state['scores'][$key]['duration_ms']) $state['scores'][$key] = $row;
                        uasort($state['scores'], fn($a,$b)=>($a['duration_ms']<=>$b['duration_ms']) ?: ($a['finished_ms']<=>$b['finished_ms']));
                        $state['scores'] = array_slice($state['scores'],0,50,true);
                        $run['submitted'] = true;
                        $run['nickname'] = $nickname;
                    }
                    $key = strtolower($run['nickname']);
                    $rank = array_search($key,array_keys($state['scores']),true);
                    $reply = ['rank'=>$rank===false?null:$rank+1,'nickname'=>$run['nickname'],'scores'=>$this->publicScores($state['scores'])];
                }
                unset($run);
            } else return [400,['error'=>'Unknown scoreboard action.']];
            // Keep the lock separate from the data file: rename is atomic even
            // when several PHP workers receive finishes at the same moment.
            $encoded = self::GUARD.json_encode($state, JSON_THROW_ON_ERROR|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES)."\n";
            $temporary = $this->directory.'/pending-'.bin2hex(random_bytes(8)).'.php';
            try {
                if (file_put_contents($temporary,$encoded)!==strlen($encoded)) throw new RuntimeException('Cannot write scores');
                @chmod($temporary,0600);
                if (!rename($temporary,$file)) throw new RuntimeException('Cannot commit scores');
            } finally { if (is_file($temporary)) @unlink($temporary); }
            return [200,$reply];
        } finally { flock($lock,LOCK_UN); fclose($lock); }
    }
    private function publicScores(array $scores): array {
        return array_map(fn($row)=>['nickname'=>$row['nickname'],'duration_ms'=>$row['duration_ms'],'enemies'=>$row['enemies'],'finished_ms'=>$row['finished_ms']],array_values(array_slice($scores,0,10,true)));
    }
}
if (defined('SUNNY_SCOUT_LIBRARY_ONLY')) return;
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: same-origin');
try {
    $method = $_SERVER['REQUEST_METHOD']??'GET';
    $origin = $_SERVER['HTTP_ORIGIN']??'';
    // Browsers use this endpoint only from the game's own origin. This is not
    // an account system or proof of client-side quest completion.
    if ($origin !== '' && parse_url($origin,PHP_URL_HOST)!==explode(':',$_SERVER['HTTP_HOST']??'')[0]) {
        http_response_code(403); echo json_encode(['error'=>'Use the scoreboard from the game website.']); exit;
    }
    $body = [];
    if ($method === 'POST') {
        if (!str_starts_with(strtolower($_SERVER['CONTENT_TYPE']??''),'application/json')) { http_response_code(415); echo json_encode(['error'=>'JSON required.']); exit; }
        $raw = file_get_contents('php://input',false,null,0,4097);
        if ($raw === false || strlen($raw)>4096) { http_response_code(413); echo json_encode(['error'=>'Request too large.']); exit; }
        $body = json_decode($raw,true,16,JSON_THROW_ON_ERROR);
        if (!is_array($body) || array_is_list($body)) { http_response_code(400); echo json_encode(['error'=>'Invalid request.']); exit; }
    }
    $defaultDirectory = __DIR__.'/data';
    // A direct versioned-release URL shares the same persistent score file.
    if (basename(dirname(__DIR__,2)) === 'releases' && preg_match('/\A[a-f0-9]{20}\z/D',basename(dirname(__DIR__)))) $defaultDirectory = dirname(__DIR__,3).'/api/data';
    $directory = getenv('SUNNY_SCOUT_DATA_DIR') ?: $defaultDirectory;
    [$status,$reply] = (new ScoutScores($directory))->request($method,$body,(int)floor(microtime(true)*1000),$_SERVER['REMOTE_ADDR']??'unknown');
    http_response_code($status); echo json_encode($reply,JSON_THROW_ON_ERROR);
} catch (JsonException $error) {
    http_response_code(400); echo json_encode(['error'=>'The scoreboard request or stored data could not be read. Please try again later.']);
} catch (Throwable $error) {
    http_response_code(503); echo json_encode(['error'=>'Shared scores are unavailable. Your adventure can still be completed.']);
}
