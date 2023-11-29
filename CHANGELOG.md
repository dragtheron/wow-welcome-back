# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

<!-- insertion marker -->
## [1.4.0-beta0](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.4.0-beta0) - 2023-11-29

<small>[Compare with 1.3.1](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.3.1...1.4.0-beta0)</small>

### Features

- introduce own activity section for current raid lockouts ([2096ef6](https://git.tsno.de/dragtheron/wow-welcome-back/commit/2096ef650e697ca6c8981caadaaab38ce7609f4a) by Tobias Stettner).
- add counter to activity categories ([d16f9d7](https://git.tsno.de/dragtheron/wow-welcome-back/commit/d16f9d76170ae36c7393f683c4df48d904551c7c) by Tobias Stettner).
- display defeat status alongside encounter times in tooltip ([7642854](https://git.tsno.de/dragtheron/wow-welcome-back/commit/7642854d9099c25a4d778a3ea34bb27f34666d3a) by Tobias Stettner).
- show tooltips for current activity encounters ([45922ce](https://git.tsno.de/dragtheron/wow-welcome-back/commit/45922cec72228c3923f91bf3349900c27c763f0d) by Tobias Stettner).
- indicate bosses with locked loot id ([1fad347](https://git.tsno.de/dragtheron/wow-welcome-back/commit/1fad347f93ed8042f8510ad0c7a6c2597d2bb76c) by Tobias Stettner).
- track save id to join activities of the same lockout ([c16a220](https://git.tsno.de/dragtheron/wow-welcome-back/commit/c16a2206f86f42362ca13a5f38177f6c49b3d3ee) by Tobias Stettner).

### Bug Fixes

- retain collapse state of character activities ([49f8271](https://git.tsno.de/dragtheron/wow-welcome-back/commit/49f82719ecf8a50c242cd6a5be6298c9e28ce585) by Tobias Stettner).

## [1.3.1](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.3.1) - 2023-11-27

<small>[Compare with 1.3.0](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.3.0...1.3.1)</small>

### Features

- update changelog ([d8faabe](https://git.tsno.de/dragtheron/wow-welcome-back/commit/d8faabef73e8d7188725af10ce5a99470591ae44) by Tobias Stettner).

### Bug Fixes

- display chat message for known player joining the group ([d4b4343](https://git.tsno.de/dragtheron/wow-welcome-back/commit/d4b4343e9d2461e7546518da9cdc4d2eaeb592e0) by Tobias Stettner).

## [1.3.0](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.3.0) - 2023-11-24

<small>[Compare with 1.2.0](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.2.0...1.3.0)</small>

### Features

- added indicator for characters with notes ([6251136](https://git.tsno.de/dragtheron/wow-welcome-back/commit/6251136727160f01d2506f37dec345f16ff3ed7d) by Tobias Stettner).
- store latest guild of character ([ffd9f2c](https://git.tsno.de/dragtheron/wow-welcome-back/commit/ffd9f2c0cfc01f76ad669e5c74198fa2e90df76f) by Tobias Stettner).
- use keystone data to track m+ dungeons ([8407c1c](https://git.tsno.de/dragtheron/wow-welcome-back/commit/8407c1c5e929e5c25899fce0a2b078af3d62ea03) by Tobias Stettner).
- add key bindings for character history ([150b53b](https://git.tsno.de/dragtheron/wow-welcome-back/commit/150b53bb94b7832fdbff22086a9292596842a136) by Tobias Stettner).
- class color names in list ([75a981f](https://git.tsno.de/dragtheron/wow-welcome-back/commit/75a981f7f53a5fb88b1068091fe8771371c03b08) by Tobias Stettner).

### Bug Fixes

- retain selected encounter journal page ([d8bb9b2](https://git.tsno.de/dragtheron/wow-welcome-back/commit/d8bb9b28d6aee80f082d2557ae1d7e4f8c6a5dbe) by Tobias Stettner).

## [1.2.0](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.2.0) - 2023-11-17

<small>[Compare with 1.2.0-beta4](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.2.0-beta4...1.2.0)</small>

### Features

- add overlay ([74b49e7](https://git.tsno.de/dragtheron/wow-welcome-back/commit/74b49e731598d8ab751fb7feb9cbc2d6783be006) by Tobias Stettner).

## [1.2.0-beta4](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.2.0-beta4) - 2023-11-16

<small>[Compare with 1.2.0-beta3](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.2.0-beta3...1.2.0-beta4)</small>

### Features

- prepare overlay ([3581318](https://git.tsno.de/dragtheron/wow-welcome-back/commit/3581318522264585f7ddbe2de2eda2c5e0576177) by Tobias Stettner).
- display total wipe count in activity summary ([3051ff0](https://git.tsno.de/dragtheron/wow-welcome-back/commit/3051ff0cffd18f8c6cec49b6780f45f7cae7fea6) by Tobias Stettner).
- add encounter times to tooltips in notes frame ([a936091](https://git.tsno.de/dragtheron/wow-welcome-back/commit/a936091a4a4555f3212c0d92c0e50fddc0dc4e2e) by Tobias Stettner).

### Bug Fixes

- hide empty notes on tooltips ([5511980](https://git.tsno.de/dragtheron/wow-welcome-back/commit/5511980a05cd0d76700512cace1e2290d401f3da) by Tobias Stettner).
- trigger update events only when necessary ([ae62109](https://git.tsno.de/dragtheron/wow-welcome-back/commit/ae62109c0ed5e67a9db6ff67dc90cba348b94627) by Tobias Stettner).

## [1.2.0-beta3](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.2.0-beta3) - 2023-11-14

<small>[Compare with 1.1.0](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.1.0...1.2.0-beta3)</small>

### Features

- add note to tooltip ([1470555](https://git.tsno.de/dragtheron/wow-welcome-back/commit/147055591ff55ebdcb41fdaa4fe13f98d85f97d5) by Tobias Stettner).
- display current activity data in notes window header ([b10328c](https://git.tsno.de/dragtheron/wow-welcome-back/commit/b10328c88030d23127414ba39e5bf28bbe088aff) by Tobias Stettner).
- use journal data ([c00eb03](https://git.tsno.de/dragtheron/wow-welcome-back/commit/c00eb0358709f9cc555633fe482316957024d40c) by Tobias Stettner).
- update on activity change ([f308515](https://git.tsno.de/dragtheron/wow-welcome-back/commit/f308515baed16a11ec16dc5f559ba052f7536a9b) by Tobias Stettner).
- disable features for dangling characters ([9eb33a7](https://git.tsno.de/dragtheron/wow-welcome-back/commit/9eb33a7412ce0030d1f941f71287895c72acd788) by Tobias Stettner).
- auto refresh on data change ([889fea4](https://git.tsno.de/dragtheron/wow-welcome-back/commit/889fea4696e8bf0030a13cfeab9aa991e5089cd0) by Tobias Stettner).
- add notes ui ([8b9a8ed](https://git.tsno.de/dragtheron/wow-welcome-back/commit/8b9a8edaf0bf396c169b5313a0ae2291c9bdde03) by Tobias Stettner).

### Bug Fixes

- delay updates to prevent freezes ([03fe4b8](https://git.tsno.de/dragtheron/wow-welcome-back/commit/03fe4b88e50e58cf4224a1e8b903112962085526) by Tobias Stettner).
- refresh behavior and list item coloring ([115ce94](https://git.tsno.de/dragtheron/wow-welcome-back/commit/115ce94962158ab80a2beea2515939a83ee44c67) by Tobias Stettner).

## [1.1.0](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.1.0) - 2023-11-09

<small>[Compare with 1.0.3](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.0.3...1.1.0)</small>

### Features

- globally save instance and difficulty names to save memory space ([9b2a89b](https://git.tsno.de/dragtheron/wow-welcome-back/commit/9b2a89b65d7430421430e8d5d3d6fbb2e39c1eeb) by Tobias Stettner).

## [1.0.3](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.0.3) - 2023-11-08

<small>[Compare with 1.0.1](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.0.1...1.0.3)</small>

### Features

- raise interface version ([8514b20](https://git.tsno.de/dragtheron/wow-welcome-back/commit/8514b20a8b8c1858c8101b89d6ccb4c906951d63) by Tobias Stettner).

## [1.0.1](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.0.1) - 2023-07-29

<small>[Compare with 1.0.0](https://git.tsno.de/dragtheron/wow-welcome-back/compare/1.0.0...1.0.1)</small>

## [1.0.0](https://git.tsno.de/dragtheron/wow-welcome-back/tags/1.0.0) - 2023-07-27

<small>[Compare with first commit](https://git.tsno.de/dragtheron/wow-welcome-back/compare/a0b30862105ea6f1b28e579ce3a7b204f430a955...1.0.0)</small>

### Features

- complete toc ([925f82d](https://git.tsno.de/dragtheron/wow-welcome-back/commit/925f82d19e3d6f26fae4b6d28aeee7a56b6cd9c8) by Tobias Stettner).

