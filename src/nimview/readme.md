Git commands that were performed to checkout / update webview
```
(from nimview base dir)
git subtree add --prefix src/nimview/webview  https://github.com/marcomq/webview.git master --squash

update to latest:
git subtree pull --prefix src/nimview/webview  https://github.com/marcomq/webview.git master --squash

push back to webview:
git subtree push --prefix src/nimview/webview  https://github.com/marcomq/webview.git master

```