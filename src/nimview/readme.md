Git commands that were performed to checkout / update webview
```
(from nimview base dir)
git subtree add --prefix src/nimview/webview  https://github.com/marcomq/webview.git master --squash
git subtree add --prefix src/nimview/webview2  https://github.com/marcomq/webview.git update --squash

update to latest:
git subtree pull --prefix src/nimview/webview  https://github.com/marcomq/webview.git master --squash
git subtree pull --prefix src/nimview/webview2  https://github.com/marcomq/webview.git update --squash

```