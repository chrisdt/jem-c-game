<?php
/** Gameplay rules shared by the plugin's WordPress and compatibility endpoints. */
declare(strict_types=1);
final class Sunny_Scout_Score_Rules {
    public const CAMPAIGN = 'three-worlds-story-v1';
    public const QUESTS = ['rowan','bea','otis','mara','iris','finn','frost_pip','frost_nix','frost_tavi','frost_eira','ember_sol','ember_luma','ember_brasa','ember_orin'];

    public static function freshState(): array {
        return ['campaign'=>self::CAMPAIGN,'runs'=>[],'scores'=>[],'rate'=>[]];
    }
    public function request(array &$state, string $method, array $body, int $now, string $address): array {
        if ($method !== 'GET' && $method !== 'POST') return [405,['error'=>'Method not allowed.']];
        if ($method === 'GET') return [200,['campaign'=>self::CAMPAIGN,'scores'=>$this->publicScores($state['scores'])]];
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
        return [200,$reply];
    }
    private function publicScores(array $scores): array {
        return array_map(fn($row)=>['nickname'=>$row['nickname'],'duration_ms'=>$row['duration_ms'],'enemies'=>$row['enemies'],'finished_ms'=>$row['finished_ms']],array_values(array_slice($scores,0,10,true)));
    }
}
