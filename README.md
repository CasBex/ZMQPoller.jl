# ZMQPoller.jl

A [ZeroMQ](https://zeromq.org/) socket poller to that integrates with the Julia task scheduler.

| **Documentation**                                                         | **Coverage**                    |
|:-------------------------------------------------------------------------:|:-------------------------------:|
| [![][docs-dev-img]][docs-dev-url] | [![][codecov-img]][codecov-url] |

__This package has been found to sometimes cause segmentation faults. Despite tests working in this repository it is strongly advised against to use this in your work!__
The package will be retained for posteriority.
The documentation contains an example on how to remove ZMQPoller.jl from your code, while still retaining functionality.

## Installation
This package is unregistered and should be installed via the URL.
This package will not be added to the Julia general registry.
```
pkg> add https://github.com/CasBex/ZMQPoller.jl
```

## Usage
The documentation provides two tutorials on usage of this package.
Otherwise refer to the [zguide](https://zguide.zeromq.org/) for more info on ZeroMQ.

## Disclaimer
The functionality in this package was proposed for merging into [ZMQ.jl](https://github.com/JuliaInterop/ZMQ.jl) and has not been accepted due to differing opinions on technical aspects.
The author of this package stands by this implementation's correctness, supported by the test suite.
For further context refer to the [original discussion](https://github.com/JuliaInterop/ZMQ.jl/pull/258) before deciding whether to use this package.

This package is intended to provide a practical, working solution, not to make a point or reopen past discussions.
Please do not engage in the original PR thread unless you have new, substantial insights.
If you encounter issues with this implementation specifically, feel free to open an issue here.

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://casbex.github.io/ZMQPoller.jl/dev

[codecov-img]: https://codecov.io/gh/CasBex/ZMQPoller.jl/graph/badge.svg?token=NMxuhZepAU
[codecov-url]: https://codecov.io/gh/CasBex/ZMQPoller.jl

