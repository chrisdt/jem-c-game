<?php
/** Private, independent Explore checkpoints. Recovery codes never appear in URLs or score rows. */
declare(strict_types=1);
if (!defined('ABSPATH')) exit;

final class Sunny_Scout_Adventure_Store {
    public const PREFIX = 'sunny_scout_adventure_v1_';
    public const MAX_BYTES = 524288;

    public function request(array $body): array {
        $action = $body['action']??'';
        if (!in_array($action,['load','save'],true)) return [400,['error'=>'Unknown adventure action.']];
        $code = $body['code']??'';
        if (!is_string($code) || !preg_match('/^[a-f0-9]{32}$/D',$code)) return [400,['error'=>'Enter the complete recovery code.']];
        $key = self::PREFIX.hash('sha256',$code);
        $before = self::read($key);
        $existing = $before === null ? null : json_decode($before,true,64,JSON_THROW_ON_ERROR);
        if ($action === 'load') {
            return $existing === null ? [404,['error'=>'No online adventure was found for that code.']]:[200,$existing];
        }
        $snapshot = $body['snapshot']??null;
        $revision = $body['revision']??null;
        $checkpoint = $body['checkpoint']??'';
        if (!is_int($revision) || $revision<0 || $revision>1000000000 || !is_string($checkpoint) || !preg_match('/^[a-f0-9]{24}$/D',$checkpoint)) return [400,['error'=>'Invalid checkpoint.']];
        // Godot's JSON reader represents integral JSON numbers as floats.
        // A recovered/offline copy may therefore serialize version as 1.0.
        if (!is_array($snapshot) || !in_array($snapshot['version']??null,[1,1.0],true) || ($snapshot['mode']??'')!=='explore' || !is_array($snapshot['state']??null)) return [400,['error'=>'Only Explore adventures can be saved.']];
        $encoded = json_encode($snapshot,JSON_THROW_ON_ERROR|JSON_UNESCAPED_SLASHES);
        if (strlen($encoded)>self::MAX_BYTES) return [413,['error'=>'This adventure is too large to save.']];
        // A timed run has no code or place in this storage. Never touches the
        // score option, run tokens or server-verified speedrun state.
        if ($existing !== null && ($existing['checkpoint']??'') === $checkpoint) {
            if (json_encode($existing['snapshot']??null,JSON_THROW_ON_ERROR|JSON_UNESCAPED_SLASHES) !== $encoded) return [409,['error'=>'Checkpoint changed. Reload your saved adventure before saving again.']];
            return [200,self::receipt($existing)]; // retry after a lost response
        }
        if (($existing['revision']??0)!==$revision) return [409,['error'=>'A newer checkpoint exists on another device. Use Continue or recover your adventure before saving again.','conflict'=>true]];
        $record = ['version'=>1,'revision'=>$revision+1,'checkpoint'=>$checkpoint,'saved_at'=>time(),'snapshot'=>$snapshot];
        $after = json_encode($record,JSON_THROW_ON_ERROR|JSON_UNESCAPED_SLASHES);
        if ($before === null) {
            if ($revision!==0) return [404,['error'=>'The online checkpoint could not be found.']];
            if (!self::allowCreate()) return [429,['error'=>'Too many new adventures today. Your checkpoint is still saved on this device.']];
            if (!add_option($key,$after,'',false)) return [409,['error'=>'The checkpoint changed. Please try again.','conflict'=>true]];
        } else {
            global $wpdb;
            $previous = $wpdb->suppress_errors(true);
            try {
                $updated = $wpdb->query($wpdb->prepare(
                    "UPDATE {$wpdb->options} SET option_value=%s WHERE option_name=%s AND BINARY option_value=BINARY %s",$after,$key,$before
                ));
                if ($updated===false) throw new RuntimeException('Adventure database write failed.');
                if ($updated!==1) return [409,['error'=>'Another device saved first. Continue from its checkpoint before saving again.','conflict'=>true]];
            } finally { $wpdb->suppress_errors($previous); }
            wp_cache_delete($key,'options');
        }
        return [200,self::receipt($record)];
    }

    private static function receipt(array $record): array {
        return array_intersect_key($record,array_flip(['version','revision','checkpoint','saved_at']));
    }

    private static function read(string $key): ?string {
        global $wpdb;
        $previous = $wpdb->suppress_errors(true);
        try {
            $value = $wpdb->get_var($wpdb->prepare("SELECT option_value FROM {$wpdb->options} WHERE option_name=%s",$key));
            if ($wpdb->last_error!=='') throw new RuntimeException('Adventure database is unavailable.');
            return $value;
        } finally { $wpdb->suppress_errors($previous); }
    }

    private static function allowCreate(): bool {
        // One atomic daily counter, independent of object-cache behavior.
        // Concurrent requests cannot all consume the same last allowance.
        global $wpdb;
        $prefix='sunny_scout_adventure_rate_v1_';
        $today=$prefix.gmdate('Ymd').'_';
        $key=$today.hash_hmac('sha256',$_SERVER['REMOTE_ADDR']??'unknown',wp_salt('nonce'));
        $previous=$wpdb->suppress_errors(true);
        try {
            add_option($key,'0','',false);
            $updated=$wpdb->query($wpdb->prepare(
                "UPDATE {$wpdb->options} SET option_value=CAST(option_value AS UNSIGNED)+1 WHERE option_name=%s AND CAST(option_value AS UNSIGNED)<30",$key
            ));
            if ($updated===false) throw new RuntimeException('Adventure rate storage is unavailable.');
            // Only this plugin's old daily counters are removed. Saves and
            // unrelated WordPress options are never part of cleanup.
            $wpdb->query($wpdb->prepare(
                "DELETE FROM {$wpdb->options} WHERE option_name LIKE %s AND option_name < %s LIMIT 1000",$wpdb->esc_like($prefix).'%', $today
            ));
            wp_cache_delete($key,'options');
            return $updated===1;
        } finally { $wpdb->suppress_errors($previous); }
    }
}
