<?php
/**
 * Plugin Name: Sunny Scout Scores
 * Description: Shared Sunny Scout times using your existing WordPress database. Activate, then use the Play Sunny Scout link.
 * Version: 1.0.0
 * Requires at least: 6.0
 * Requires PHP: 8.1
 * Author: Sunny Scout
 * License: GPL-2.0-or-later
 * Text Domain: sunny-scout-scores
 */
declare(strict_types=1);
if (!defined('ABSPATH')) exit;
require_once __DIR__.'/score-rules.php';

final class Sunny_Scout_WordPress_Store {
    public const OPTION = 'sunny_scout_scores_three_worlds_v1';

    public static function initialize(): void {
        // WordPress handles credentials and installation. Do not autoload the
        // score state on unrelated site pages or cache it through get_option().
        add_option(self::OPTION, json_encode(Sunny_Scout_Score_Rules::freshState(), JSON_THROW_ON_ERROR), '', false);
        self::read();
    }

    private static function read(): string {
        global $wpdb;
        $previous = $wpdb->suppress_errors(true);
        try {
            $value = $wpdb->get_var($wpdb->prepare(
                "SELECT option_value FROM {$wpdb->options} WHERE option_name = %s", self::OPTION
            ));
            if ($wpdb->last_error !== '' || !is_string($value)) throw new RuntimeException('Score database is unavailable.');
            return $value;
        } finally { $wpdb->suppress_errors($previous); }
    }

    public function request(string $method, array $body, int $now, string $address): array {
        global $wpdb;
        $rules = new Sunny_Scout_Score_Rules();
        for ($attempt = 0; $attempt < 16; $attempt++) {
            $before = self::read();
            if (strlen($before) > 4*1024*1024) throw new RuntimeException('Score database state is too large.');
            $state = json_decode($before, true, 32, JSON_THROW_ON_ERROR);
            if (!is_array($state) || ($state['campaign']??'') !== Sunny_Scout_Score_Rules::CAMPAIGN) throw new RuntimeException('Score database version is invalid.');
            foreach (['runs','scores','rate'] as $key) {
                if (!isset($state[$key]) || !is_array($state[$key])) throw new RuntimeException('Score database state is invalid.');
            }
            [$status,$reply] = $rules->request($state,$method,$body,$now,$address);
            if ($method === 'GET' || $status !== 200) return [$status,$reply];
            $after = json_encode($state, JSON_THROW_ON_ERROR|JSON_UNESCAPED_SLASHES);
            if ($before === $after) return [$status,$reply];
            // Atomic compare-and-swap prevents two PHP workers losing each
            // other's updates. Binary comparison ignores database collation.
            $previous = $wpdb->suppress_errors(true);
            try {
                $updated = $wpdb->query($wpdb->prepare(
                    "UPDATE {$wpdb->options} SET option_value = %s WHERE option_name = %s AND BINARY option_value = BINARY %s",
                    $after, self::OPTION, $before
                ));
                if ($updated === false) throw new RuntimeException('Score database write failed.');
            } finally { $wpdb->suppress_errors($previous); }
            if ($updated === 1) {
                wp_cache_delete(self::OPTION, 'options');
                return [$status,$reply];
            }
            // A concurrent start/finish won the update; re-read and apply the
            // original request against it, keeping the original server time.
            usleep(random_int(1000,5000)*($attempt+1));
        }
        throw new RuntimeException('Score database is busy. Please retry.');
    }
}

final class Sunny_Scout_Scores_Plugin {
    private const ROUTE = '/sunny-scout/';

    public static function activate(): void {
        try { Sunny_Scout_WordPress_Store::initialize(); }
        catch (Throwable $error) {
            self::log($error,'activation','setup');
            wp_die(esc_html('Sunny Scout could not initialize score storage in the WordPress database. Please check the PHP error log.'), 'Sunny Scout Scores', ['back_link'=>true]);
        }
        set_transient('sunny_scout_scores_activated',1,60);
    }

    public static function boot(): void {
        add_action('rest_api_init', [self::class,'registerRest']);
        // These virtual routes work with either plain or pretty permalinks.
        // They do not edit .htaccess, the old PHP endpoint, or game files.
        add_action('parse_request', [self::class,'virtualRoute'], 0);
        add_action('admin_menu', static function(): void {
            add_management_page('Sunny Scout Scores','Sunny Scout Scores','manage_options','sunny-scout-scores',[self::class,'adminPage']);
        });
        add_action('admin_notices', [self::class,'activationNotice']);
        add_filter('plugin_action_links_'.plugin_basename(__FILE__), static function(array $links): array {
            array_unshift($links,'<a href="'.esc_url(self::playUrl()).'">Play Sunny Scout</a>');
            return $links;
        });
    }

    public static function playUrl(): string { return home_url('/index.php?sunny_scout=play'); }

    public static function apiUrl(): string {
        // Explicit index.php also works when root index.html is the game and
        // WordPress uses plain permalinks. No new physical PHP file is needed.
        return home_url('/index.php?rest_route=/sunny-scout/v1/leaderboard');
    }

    public static function registerRest(): void {
        register_rest_route('sunny-scout/v1','/leaderboard',[
            'methods'=>['GET','POST'],
            'permission_callback'=>'__return_true',
            'callback'=>[self::class,'restRequest'],
        ]);
    }

    public static function restRequest(WP_REST_Request $request): WP_REST_Response {
        [$status,$reply] = self::handle(
            $request->get_method(), (string)$request->get_header('origin'),
            (string)$request->get_header('content-type'), $request->get_body()
        );
        $response = new WP_REST_Response($reply,$status);
        $response->header('Cache-Control','no-store, no-cache, must-revalidate, max-age=0');
        $response->header('X-Content-Type-Options','nosniff');
        return $response;
    }

    private static function handle(string $method, string $origin, string $contentType, string $raw): array {
        $action = 'board';
        try {
            if ($origin !== '' && strcasecmp((string)wp_parse_url($origin,PHP_URL_HOST),(string)wp_parse_url(home_url(),PHP_URL_HOST)) !== 0) {
                return [403,['error'=>'Use the scoreboard from the game website.']];
            }
            if (!in_array($method,['GET','POST'],true)) return [405,['error'=>'Method not allowed.']];
            $body = [];
            if ($method === 'POST') {
                if (!str_starts_with(strtolower($contentType),'application/json')) return [415,['error'=>'JSON required.']];
                if (strlen($raw) > 4096) return [413,['error'=>'Request too large.']];
                try { $body = json_decode($raw,true,16,JSON_THROW_ON_ERROR); }
                catch (JsonException $error) { return [400,['error'=>'Invalid request.']]; }
                if (!is_array($body) || array_is_list($body)) return [400,['error'=>'Invalid request.']];
                $action = $body['action']??'unknown';
            }
            return (new Sunny_Scout_WordPress_Store())->request(
                $method,$body,(int)floor(microtime(true)*1000),$_SERVER['REMOTE_ADDR']??'unknown'
            );
        } catch (Throwable $error) {
            self::log($error,$method,$action);
            return [503,['error'=>'Shared scores are unavailable. Your adventure can still be completed.']];
        }
    }

    private static function log(Throwable $error, string $method, mixed $action): void {
        $action = in_array($action,['board','start','complete','submit','setup'],true) ? $action : 'unknown';
        $method = in_array($method,['GET','POST','activation'],true) ? $method : 'other';
        error_log('Sunny Scout WordPress scores: '.json_encode([
            'method'=>$method,'action'=>$action,'exception'=>get_class($error),'detail'=>$error->getMessage()
        ],JSON_UNESCAPED_SLASHES|JSON_INVALID_UTF8_SUBSTITUTE));
    }

    public static function virtualRoute(): void {
        $path = wp_parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH);
        $indexPath = wp_parse_url(home_url('/index.php'),PHP_URL_PATH);
        if ($path === $indexPath && ($_GET['sunny_scout']??null) === 'play') self::serveGame();
        // Friendly aliases work where normal WordPress pretty routing is
        // enabled. The advertised index.php link requires no rewrite setup.
        $prettyPath = wp_parse_url(home_url(self::ROUTE),PHP_URL_PATH);
        if ($path === $prettyPath || $path === rtrim($prettyPath,'/')) self::serveGame();
    }

    public static function gameEntry(): ?array {
        // The game can already be at the WordPress root, in /play/, or have
        // a versioned <base> from the existing deployment tool.
        foreach ([''=>'/','play/'=>'/play/'] as $directory=>$urlPath) {
            $path = ABSPATH.$directory.'index.html';
            if (!is_file($path) || !is_readable($path) || filesize($path) > 2*1024*1024) continue;
            $html = file_get_contents($path);
            if (!is_string($html) || !str_contains($html,'new Engine(') || !str_contains($html,'index.pck')) continue;
            return ['html'=>$html,'base'=>home_url($urlPath),'location'=>$directory === '' ? 'WordPress root' : '/play/'];
        }
        return null;
    }

    private static function serveGame(): void {
        if (!defined('DONOTCACHEPAGE')) define('DONOTCACHEPAGE',true);
        nocache_headers();
        $entry = self::gameEntry();
        if ($entry === null) {
            wp_die('Sunny Scout game files were not found. Keep the exported game files in the WordPress root or /play/.','Sunny Scout',['response'=>503]);
        }
        $html = $entry['html'];
        $extra = '';
        if (!preg_match('/<base\s/i',$html)) $extra .= '<base href="'.esc_url($entry['base']).'">';
        // Older exported games compute their score URL internally. Adapt just
        // those fetch calls on this Play page, so they work with the installed
        // plugin without uploading another 100 MB game or rewriting PHP files.
        // REST goes through an existing WordPress file; nginx may reject a
        // nonexistent *.php virtual URL before WordPress can route it.
        $api = wp_json_encode(self::apiUrl(),JSON_HEX_TAG|JSON_HEX_AMP|JSON_HEX_APOS|JSON_HEX_QUOT);
        $extra .= '<script>(()=>{window.scoutScoresEndpoint='.$api.';const send=window.fetch.bind(window);const paths=[new URL("api/leaderboard.php",location.href).pathname,new URL("api/leaderboard.php",document.baseURI).pathname];window.fetch=(input,init)=>{const source=new URL(input instanceof Request?input.url:String(input),document.baseURI);if(source.origin===location.origin&&paths.includes(source.pathname)){const target=new URL(window.scoutScoresEndpoint);if(source.searchParams.has("fresh"))target.searchParams.set("fresh",source.searchParams.get("fresh"));input=input instanceof Request?new Request(target.href,input):target.href}return send(input,init)}})();</script>';
        $html = preg_replace_callback('/<head\b[^>]*>/i',static fn($match)=>$match[0].$extra,$html,1,$count);
        if ($count !== 1) wp_die('The Sunny Scout game HTML is incomplete.','Sunny Scout',['response'=>503]);
        status_header(200);
        header('Content-Type: text/html; charset=utf-8');
        echo $html;
        exit;
    }

    public static function activationNotice(): void {
        if (!current_user_can('manage_options') || !get_transient('sunny_scout_scores_activated')) return;
        delete_transient('sunny_scout_scores_activated');
        echo '<div class="notice notice-success"><p>Sunny Scout Scores is ready. <a href="'.esc_url(self::playUrl()).'">Play Sunny Scout</a> using the WordPress leaderboard.</p></div>';
    }

    public static function adminPage(): void {
        if (!current_user_can('manage_options')) return;
        echo '<div class="wrap"><h1>Sunny Scout Scores</h1>';
        try {
            [$status,$board] = (new Sunny_Scout_WordPress_Store())->request('GET',[],(int)floor(microtime(true)*1000),'admin');
            echo '<p>Score storage is ready in your existing WordPress database.</p>';
        } catch (Throwable $error) {
            echo '<p>Score storage could not be read. Check the PHP error log for Sunny Scout WordPress scores.</p>';
        }
        $entry = self::gameEntry();
        if ($entry === null) echo '<p>Game files were not found. Keep the exported game files in the WordPress root or /play/.</p>';
        else echo '<p>Game files found: '.esc_html($entry['location']).'.</p>';
        echo '<p><a class="button button-primary" href="'.esc_url(self::playUrl()).'">Play Sunny Scout</a></p>';
        echo '<p>Share this game link: <code>'.esc_html(self::playUrl()).'</code></p>';
        echo '<p>Use this link for the database-backed leaderboard. Your previous game URL can still use its old score endpoint.</p>';
        echo '<p>Fresh leaderboard · All 14 story quests · One best time per nickname</p></div>';
    }
}

register_activation_hook(__FILE__,[Sunny_Scout_Scores_Plugin::class,'activate']);
Sunny_Scout_Scores_Plugin::boot();
