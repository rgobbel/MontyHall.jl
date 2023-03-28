#!julia
# A simulation of the "Monty Hall" problem, for any number of doors.
using Logging: global_logger
using TerminalLoggers: TerminalLogger
global_logger(TerminalLogger(right_justify=120))
using ProgressLogging, Format, ArgParse

VERBOSE = false

@enum Decision stay switch
@enum Outcome win lose


#=
Print the results of a simulation run.
=#
function print_stats(n_trials::Int, n_doors::Int, n_opens::Int, 
		stats::Dict{Tuple{Decision, Outcome}, Int})
	stay_win = stats[(stay, win)]
	stay_lose = stats[(stay, lose)]
	switch_win = stats[(switch, win)]
	switch_lose = stats[(switch, lose)]
	total_wins = stay_win + switch_win
	total_losses = stay_lose + switch_lose
	total_switches = switch_win + switch_lose
	total_stays = stay_win + stay_lose

	stay_ratio = stay_win / total_stays
	switch_ratio = switch_win / total_switches
	advantage = switch_ratio / stay_ratio

	ii(n) = cfmt("%'d", n)
	println("$(ii(n_trials)) trials, $(ii(n_doors)) doors, $(ii(n_opens)) opens")
	println("wins = switch:$(ii(switch_win)), stay:$(ii(stay_win))")
	println("losses = switch:$(ii(switch_lose)), stay:$(ii(stay_lose))")
	println("switch: win:$(ii(switch_win)), lose:$(ii(switch_lose))")
	println("stay: win:$(ii(stay_win)), lose:$(ii(stay_lose))")
	println("stay win/loss ratio = $(stay_ratio)")
	println("switch win/loss ratio = $(switch_ratio)")
	println("switch/stay advantage = $(advantage)")

	pre_prob = 1 / n_doors
	post_prob = ((n_doors - 1) / (n_doors - n_opens - 1)) / n_doors
	println("pre-reveal chance correct =  $(pre_prob)")
	println("post-reveal switch chance correct = $(post_prob)")
	err = abs(((switch_ratio - post_prob) + (stay_ratio - pre_prob)) / 2)
	println("error = $(err)")
end

#=
Generalized "Monty Hall" problem, with any number of doors, any number of
doors opened, and simulating any number of trials. Optimized to skip over
cases that don't need to be computed.
=#
function simulate_monty(;n_trials::Int, n_doors::Int, n_opens::Int)
	
    @assert n_opens < n_doors-1 "n_opens is not less than n_doors-1 ($n_opens, $n_doors)\n"
    
    stats = Dict{Tuple{Decision, Outcome}, Int}(
	((stay, win) => 0),
	((stay, lose) => 0),
	((switch, win) => 0),
	((switch, lose) => 0)
    )
    
    @progress for trial in 1:n_trials
	car_door = rand(1:n_doors)
	first_choice = 1
	final_choice = 0 # a losing value
        
	decision = rand([switch, stay])
        
	if decision == stay
	    final_choice = first_choice
	else
	    if first_choice != car_door # otherwise final_choice is a losing value
		last_after_opens = n_doors - n_opens
		if car_door <= last_after_opens # no need to move anything
		    final_choice = rand(2:last_after_opens)
		else
		    doors = cat(2:last_after_opens-1, car_door, dims=1)
		    final_choice = rand(doors)
		end
	    end
	end
        
	outcome = final_choice == car_door ? win : lose
        
	stats[(decision, outcome)] += 1
    end
    
    print_stats(n_trials, n_doors, n_opens, stats)
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
    simulate_monty(n_trials=args["trials"],  n_doors=args["doors"], n_opens=args["opens"])
end

main()
