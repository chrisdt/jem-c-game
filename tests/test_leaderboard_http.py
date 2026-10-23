"""Run the real PHP endpoint and Godot client against disposable local files."""
import concurrent.futures
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.request
import urllib.error

ROOT=Path(__file__).resolve().parents[1]
PHP=os.environ.get('SCOUT_TEST_PHP','php')
QUESTS=['rowan','bea','otis','mara','iris','finn','frost_pip','frost_nix','frost_tavi','frost_eira','ember_sol','ember_luma','ember_brasa','ember_orin']
CAMPAIGN='three-worlds-story-v1'
def run():
 with tempfile.TemporaryDirectory(prefix='scout-board-test-') as tmp:
  root=Path(tmp); web=root/'web'; (web/'api').mkdir(parents=True)
  shutil.copy2(ROOT/'server/leaderboard.php',web/'api/leaderboard.php')
  with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
  endpoint=f'http://127.0.0.1:{port}/api/leaderboard.php'
  env=os.environ|{'SUNNY_SCOUT_DATA_DIR':str(root/'data'),'PHP_CLI_SERVER_WORKERS':'4'}
  log=(root/'php.log').open('w')
  server=subprocess.Popen([PHP,'-n','-S',f'127.0.0.1:{port}','-t',str(web)],env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
  opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
  def request(body=None,headers=None,method=None):
   data=None if body is None else json.dumps(body).encode()
   head=({'Content-Type':'application/json'} if data is not None else {})|(headers or {})
   req=urllib.request.Request(endpoint,data=data,headers=head,method=method)
   try:r=opener.open(req,timeout=15)
   except urllib.error.HTTPError as e:r=e
   return r.status,dict(r.headers),json.loads(r.read())
  try:
   deadline=time.monotonic()+10
   while True:
    try:
     code,headers,data=request();break
    except (OSError,urllib.error.URLError):
     if time.monotonic()>deadline:raise
     time.sleep(.05)
   assert code==200 and data['scores']==[] and 'no-store' in headers.get('Cache-Control','')
   assert request({'action':'start','campaign':CAMPAIGN},{'Origin':'https://another.example'})[0]==403
   assert request({'action':'start','campaign':CAMPAIGN},{'Content-Type':'text/plain'})[0]==415
   assert request(method='PUT')[0]==405
   assert request({'action':'start','campaign':CAMPAIGN,'large':'x'*5000})[0]==413
   # Exercise the production client's HTTPRequest and modal submission flow.
   godot_env=env|{'XDG_DATA_HOME':'/workspace/.runtime/data','XDG_CONFIG_HOME':'/workspace/.runtime/config','XDG_CACHE_HOME':'/workspace/.runtime/cache'}
   client_log=Path('/tmp/scout-http-godot.log')
   with client_log.open('w') as output:
    result=subprocess.run(['godot','--headless','--path',str(ROOT),'--script','tests/speedrun_online.gd','--',endpoint,str(root/'data/scores.php')],env=godot_env,stdout=output,stderr=subprocess.STDOUT,text=True,timeout=120)
   client_output=client_log.read_text()
   print(client_output,end='',flush=True)
   assert result.returncode==0 and 'ERROR:' not in client_output
   # Concurrent PHP workers, not merely several calls on one interpreter.
   def register(_):return request({'action':'start','campaign':CAMPAIGN})
   with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool: replies=list(pool.map(register,range(16)))
   tokens=[r[2]['token'] for r in replies if r[0]==200]
   assert len(tokens)==16 and len(set(tokens))==16
   raw=(root/'data/scores.php').read_text().split('\n',1)[1];state=json.loads(raw)
   assert all(t in state['runs'] for t in tokens)
   assert request()[2]['scores'][0]['nickname']=='JeremyTest'
   # Reproduce a host that can read/lock existing data but cannot create
   # a replacement score file. Existing scores must survive, the browser
   # receives no private paths, and the real reason reaches PHP's log.
   directory=root/'data'; before=(directory/'scores.php').read_bytes()
   directory.chmod(0o500)
   try:
    code,_,reply=request({'action':'start','campaign':CAMPAIGN,'nickname':'NeverLogThisNickname','token':'NeverLogThisToken'})
    assert code==503 and reply=={'error':'Shared scores are unavailable. Your adventure can still be completed.'}
    assert (directory/'scores.php').read_bytes()==before
    assert request()[0]==200
    diagnostic=(root/'php.log').read_text()
    assert 'Sunny Scout scoreboard:' in diagnostic and 'Cannot write scores:' in diagnostic and 'Permission denied' in diagnostic
    assert 'NeverLogThisNickname' not in diagnostic and 'NeverLogThisToken' not in diagnostic
    assert all(token not in diagnostic for token in tokens)
   finally: directory.chmod(0o700)
   assert request({'action':'start','campaign':CAMPAIGN})[0]==200
   assert request()[2]['scores'][0]['nickname']=='JeremyTest'
   print('PASS: HTTP/client/concurrency, read-only storage reproduction, private PHP diagnostics without token leakage, preserved scores and recovery after restoring write access',flush=True)
  finally:
   import signal
   os.killpg(server.pid,signal.SIGTERM)
   server.wait(timeout=10);log.close()
if __name__=='__main__':run()
