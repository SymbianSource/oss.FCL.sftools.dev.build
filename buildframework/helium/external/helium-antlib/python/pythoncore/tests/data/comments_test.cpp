// <branchInfo originator="prozeniu" error="wiki-07wk24-311" since="07-06-14" category="fix">
// We need TwistOpen and TwistClose to cause display to change between
// landscape and portrait, but SysAp is consuming the key events.  Try
// treating them as Flip events are handled already by SysAp.
// </branchInfo>
// BRANCH 07-06-14