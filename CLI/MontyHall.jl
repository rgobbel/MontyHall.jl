#!julia

# A simulation of the "Monty Hall" problem, for an arbitrary number of doors.
using Logging: global_logger
using TerminalLoggers: TerminalLogger
global_logger(TerminalLogger(right_justify=120))
using ProgressLogging, Format, ArgParse

VERBOSE = false

# Print the results of a simulation run.
function print_stats(n_trials::T, n_doors::T, n_opens::T, 
		stay_win::T, switch_win::T) where {T<:Int}
	stay_ratio::Float32 = stay_win / n_trials
	switch_ratio::Float32 = switch_win / n_trials
	advantage::Float32 = switch_ratio / stay_ratio

	ii(n) = cfmt("%'d", n)
	println("$(ii(n_trials)) trials, $(ii(n_doors)) doors, $(ii(n_opens)) opens")
	println("wins = switch:$(ii(switch_win)), stay:$(ii(stay_win))")
	println("stay win/loss ratio = $(stay_ratio)")
	println("switch win/loss ratio = $(switch_ratio)")
	println("switch/stay advantage = $(advantage)")

	pre_prob::Float32 = 1 / n_doors
	post_prob::Float32 = ((n_doors - 1) / (n_doors - n_opens - 1)) / n_doors
	println("pre-reveal chance correct =  $(pre_prob)")
	println("post-reveal switch chance correct = $(post_prob)")
	err::Float32 = abs(((switch_ratio - post_prob) + (stay_ratio - pre_prob)) / 2)
	println("error = $(err)")
end

#=
Generalized "Monty Hall" problem, with any number of doors, any number of
doors opened, and simulating any number of trials. Optimized to skip over
cases that don't need to be computed.
=#
function simulate_monty(;trials::T, doors::T, opens::T) where T<:Int
    opens < doors-1 || throw(DomainError("opens=$opens, doors=$doors", "opens must be <= than doors-2"))
    
    stay_wins::T = 0
    switch_wins::T = 0
    i_last::T = doors - opens
    
    for trial in 1:trials
	    car::T = rand(1:doors)
        if car == 1
            stay_wins += 1
        end
	    switch_choice::T = rand(2:i_last)
        if car > i_last
            switch_choice += car - i_last
        end
        if switch_choice == car
            switch_wins += 1
        end
    end

    print_stats(trials, doors, opens, stay_wins, switch_wins)
end

function parse_command_line()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--trials", "-t"
        help = "number of trials to run"
        arg_type = Int
        default = 100000
        "--doors", "-d"
        help = "total number of doors"
        arg_type = Int
        default = 3
        "--opens", "-o"
        help = "number of doors to open after initial choice"
        arg_type = Int
        default = 1
    end
    parse_args(s)
end

function main()
    args = parse_command_line()
    @time simulate_monty(trials=args["trials"],  doors=args["doors"], opens=args["opens"])
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
