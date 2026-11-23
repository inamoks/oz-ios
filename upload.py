
import base64, json, os, ssl, urllib.request, urllib.error

TOK = open(r"C:/Users/hp/Downloads/gh-token.txt", encoding="utf-8").read().strip()
API = "https://api.github.com"
OWNER = "inamoks"
REPO = "oz-ios"
BASE = r"C:/Users/hp/Downloads/ios-app"
CTX = ssl._create_unverified_context()

def call(method, path, body=None, raw=False):
    url = path if path.startswith("http") else API + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "token " + TOK,
        "Accept": "application/vnd.github+json",
        "User-Agent": "oz-build",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=60, context=CTX) as r:
            b = r.read()
            return r.status, (b if raw else json.loads(b.decode("utf-8", "ignore") or "{}"))
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "ignore")[:300]
    except Exception as e:
        return -1, str(e)[:200]

# 1) 仓库
st, info = call("GET", f"/repos/{OWNER}/{REPO}")
if st == 404:
    st, info = call("POST", "/user/repos", {"name": REPO, "private": True, "auto_init": True})
    print("create repo:", st, str(info)[:100] if st != 201 else "ok")
else:
    print("repo exists:", st, info.get("default_branch") if isinstance(info, dict) else info)

branch = "main"
st, meta = call("GET", f"/repos/{OWNER}/{REPO}")
if isinstance(meta, dict):
    branch = meta.get("default_branch", "main")
print("branch:", branch)

# 2) 逐文件上传
skip_dirs = {".git", "__pycache__"}
files = []
for root, dirs, names in os.walk(BASE):
    dirs[:] = [d for d in dirs if d not in skip_dirs]
    for n in names:
        if n in ("_me.json",) or n.endswith(".pyc"):
            continue
        fp = os.path.join(root, n)
        rel = os.path.relpath(fp, BASE).replace("\\", "/")
        files.append((rel, fp))
files.sort()
print("files:", len(files))

ok = fail = 0
for rel, fp in files:
    content = base64.b64encode(open(fp, "rb").read()).decode()
    st, res = call("PUT", f"/repos/{OWNER}/{REPO}/contents/{rel}", {
        "message": "add " + rel,
        "content": content,
        "branch": branch,
    })
    if st in (200, 201):
        ok += 1
    else:
        fail += 1
        print("  FAIL", rel, st, str(res)[:120])
print("uploaded:", ok, "failed:", fail)
