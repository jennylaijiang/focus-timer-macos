# Before each release

- [ ] Finish the intended changes and merge them into `main`.
- [ ] Update `CFBundleShortVersionString` (app version) and increment `CFBundleVersion` (build number) in [Resources/Info.plist](../Resources/Info.plist).
- [ ] Build the release app and run automated tests using the [README commands](../README.md).
- [ ] Try the built app: start, pause, finish, save thoughts, quit, reopen, and check history. Test changed features and any affected recovery behavior.
- [ ] Update [verification notes](verification.md) and prepare brief release notes covering changes, known limitations, and any checks not performed.
- [ ] Commit and push the release changes, then tag that exact commit (for example, `v1.1.0`) and push the tag. If code or build settings changed after testing, rebuild and repeat the affected checks first.
- [ ] If distributing the app, ZIP the verified build from that commit and attach it to the GitHub Release with the release notes.
