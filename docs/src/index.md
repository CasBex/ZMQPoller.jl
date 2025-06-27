# ZMQPoller.jl

This package implements a ZMQ socket poller that integrates with the Julia task scheduler.
!!! warning
	This poller has not been accepted for merging into [ZMQ.jl](https://github.com/JuliaInterop/ZMQ.jl) due to differing opinions on technical aspects.
	The author of this package stands by this implementation's correctness, supported by the test suite.
	For further context refer to the [original discussion](https://github.com/JuliaInterop/ZMQ.jl/pull/258).

	**Disclaimer**: This package is intended to provide a practical, working solution, not to make a point or reopen past discussions.
	Please do not engage in the original PR thread unless you have new, substantial insights.
	If you encounter issues with this implementation specifically, feel free to open an issue here.
