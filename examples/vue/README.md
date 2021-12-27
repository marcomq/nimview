## Nimview Vue sample application

- npm install
- npm run build
- nim c -r -d:release --app:gui src/App.nim
- (or, if you want to have an async count down button: `nim c -r -d:release --gc:orc --threads:on --app:gui src/App.nim`)