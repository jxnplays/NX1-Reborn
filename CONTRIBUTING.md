# Contributing

This is a maintained fork of [NX1recomp](https://github.com/goshavindtburg/NX1recomp). Contributions are welcome, with a few constraints.

## Scope

- Runtime fixes, netplay improvements, and renderer work are in scope.
- Do not commit game code, assets, or generated C++. Those stay out of the repository.
- `thirdparty/` is gitignored. Do not attempt to vendor it.

## Building

See the README. You need the Internet Archive v1.1.1.14 dump in `nx1/` and a restored `thirdparty/` tree before a build will succeed.

## Reporting issues

Include the target (`nx1_sp` or `nx1_mp`), the dump version, and a short description of what you expected versus what happened. Logs from the build directory help.
