### A Pluto.jl notebook ###
# v0.19.22

#> [frontmatter]
#> title = "Generalized Monty Hall"
#> description = "A simulation of the \"Monty Hall\" problem, for any number of doors."

using Markdown
using InteractiveUtils

# ╔═╡ 5363cfdd-63c5-4559-aba2-6ef520dbab12
using ProgressLogging, Format

# ╔═╡ 1f2421cb-9730-4af5-a112-440e681db9c5
md"""
# The "Monty Hall" problem in Julia
"""

# ╔═╡ a43e93b5-8e69-45a1-ad5f-77298b0a3217
VERBOSE = false

# ╔═╡ 7312b7b0-c023-437f-821e-71eee38da234
md"""
##### Run the simulation
In this default example, we run 100,000 trials, with 1,000 doors. After the player chooses one door, the host opens 998 of the remaining 999 doors.

Simulation results are checked against numerically-computed values. For any reasonable number of runs (say 1000 or more), any error > 0.002 indicates a bug
in the simulation. The error should decrease as the number of runs increases.
"""

# ╔═╡ bc84bb6c-6a34-40db-be89-19145ab01f69
md"""
##### Main simulation code
"""

# ╔═╡ 31bdb98b-33e5-44be-b35a-7d8d4a7789f1
@enum Decision stay switch

# ╔═╡ 4f3d46be-4d4a-453f-b062-a6afd51b4b33
@enum Outcome win lose

# ╔═╡ 1bf7657d-1886-497a-9d73-a13c443a107d
md"""
##### Print out simulation results at the end of a run
"""

# ╔═╡ 8d94575e-8258-4916-9ef3-dbd99fbb8a1d
#=
Print the results of a simulation run.
do_probs controls printout of theoretical probabilities,
as well as accumulated simulation results.
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

# ╔═╡ d0c6c99c-74f1-4f6c-a9cf-832da99c6f1e
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

# ╔═╡ 8cf35575-5e1a-42d3-bc98-930f1d31bbba
simulate_monty(n_trials=1_000_000, n_doors=1_000, n_opens=998)

# ╔═╡ bcf4d581-eda0-47c3-8c3c-17f00e3ac511
#=
Print the results of a simulation run.
do_probs controls printout of theoretical probabilities,
as well as accumulated simulation results.
=#
#=
function print_stats(n_trials::Int, n_doors::Int, n_opens::Int, wins, losses, do_probs=true)
	total_wins = wins[:switch] + wins[:stay]
	total_losses = losses[:switch] + losses[:stay]
	total_switches = wins[:switch] + losses[:switch]
	total_stays = wins[:stay] + losses[:stay]

	stay_ratio = wins[:stay] / total_stays
	switch_ratio = wins[:switch] / total_switches
	advantage = switch_ratio / stay_ratio
	
	print("$n_trials trials, $n_doors doors, $n_opens opens\n")
	print("wins = switch:$(wins[:switch]), stay:$(wins[:stay])\n")
	print("losses = switch:$(losses[:switch]), stay:$(losses[:stay])\n")
	print("switch: win:$(wins[:switch]), lose:$(losses[:switch])\n")
	print("stay: win:$(wins[:stay]), lose:$(losses[:stay])\n")
	print("stay win/loss ratio = $(stay_ratio)\n")
	print("switch win/loss ratio = $(switch_ratio)\n")
	print("switch/stay advantage = $(advantage)\n")
	if do_probs
		pre_prob = 1 / n_doors
		post_prob = ((n_doors - 1) / (n_doors - n_opens - 1)) / n_doors
		print("pre-reveal chance correct =  $(pre_prob)\n")
		print("post-reveal switch chance correct = $(post_prob)\n")
		err = abs(((switch_ratio - post_prob) + (stay_ratio - pre_prob)) / 2)
		print("error = $(err)\n")
	end
end
=#

# ╔═╡ 5bb70c2f-8d41-453e-9761-2585ec177403
md"""
Older, slower versions of the simulation code
"""

# ╔═╡ 3b6add7c-a77c-4786-b4d9-ddee1823bbb0
# ╠═╡ disabled = true
#=╠═╡
function simulate_monty1(n_trials::Int, n_doors::Int, n_opens::Int, trace=false)
	@assert n_opens < n_doors-1 "n_opens is not less than n_doors-1 ($n_opens, $n_doors)\n"
	wins = Dict(:switch=>0, :stay=>0)
	losses = Dict(:switch=>0, :stay=>0)
	ran = !trace
	@progress for trial in 1:n_trials
		final_choice = 0
		doors = collect(1:n_doors)
		# if !ran
		# 	print("doors at start = $doors\n")
		# end
		car_door = rand(doors)
		first_choice = pop!(doors)
		# if !ran
		# 	print("first:$first_choice, car:$car_door\n")
		# end
		#doors = setdiff(doors, [first_choice])
		if !ran
			print("doors after player choice removed = $doors\n")
		end
		
		switch = rand([true, false])
		if switch
			if first_choice == car_door # we were already right
				win = false
				final_choice = 0
			else # first choice was wrong. Might win by switching
				setdiff!(doors, car_door) # remove car from set to be revealed
				if !ran
					print("doors after car removed = $doors\n")
				end
				resize!(doors, length(doors)-n_opens)
				if !ran
					print("doors after reveal = $doors\n")
				end
		
				push!(doors, car_door)
				if !ran
					print("doors after car replaced = $doors\n")
				end
				final_choice = rand(doors)
				win = final_choice == car_door
			end
		else
			final_choice = first_choice
			win = final_choice == car_door
		end
		
		if !ran
			print("\nswitch:$switch, win:$win\n")
			print("doors:$doors, car:$car_door, first:$first_choice, final:$final_choice\n")
			# print("host_choices:$host_choices, removed:$removed\n")
		end
		if win
			if switch
				wins[:switch] += 1
			else
				wins[:stay] += 1
			end
		else
			if switch	
				losses[:switch] += 1
			else
				losses[:stay] += 1
			end
		end
	ran = true
	end
	print("\n")
	print_stats(n_trials, n_doors, n_opens, wins, losses)
end
  ╠═╡ =#

# ╔═╡ f12a9f27-3ae5-447f-b747-5898596bca96
# ╠═╡ disabled = true
#=╠═╡
function simulate_monty2(n_trials::Int, n_doors::Int, n_opens::Int, trace=false)
	@assert n_opens < n_doors-1 "n_opens is not less than n_doors-1 ($n_opens, $n_doors)\n"
	wins = Dict(:switch=>0, :stay=>0)
	losses = Dict(:switch=>0, :stay=>0)
	ran = !trace
	for trial in 1:n_trials
		doors = collect(1:n_doors)
		if !ran
			print("doors at start = $doors\n")
		end
		car_door = rand(doors)
		first_choice = rand(doors)
		setdiff!(doors, first_choice)
		if !ran
			print("doors after player choice = $doors\n")
		end
		if first_choice != car_door
			setdiff!(doors, car_door)
		end
		if !ran
			print("doors after car removed = $doors\n")
		end
		if !ran
			print("player:$first_choice, car:$car_door\n")
		end
		#doors = setdiff(doors, [first_choice])
		if first_choice == car_door
			resize!(doors, length(doors)-n_opens+1)
		else
			resize!(doors, length(doors)-n_opens)
		end
		# for i in 1:n_opens
		# 	x = rand(doors)
		# 	setdiff!(doors, x)
		# end
		if !ran
			print("doors after reveal = $doors\n")
		end

		if first_choice != car_door # put car_door back after reveal
			push!(doors, car_door)
		end
		if !ran
			print("doors after car replaced = $doors\n")
		end

		switch = rand([true, false])
		
		if switch
			final_choice = rand(doors)
		else
			final_choice = first_choice
		end

		win = final_choice == car_door
		
		if !ran
			print("\nwin:$win, switch:$switch\n")
			print("doors:$doors, car:$car_door, first:$first_choice, final:$final_choice\n")
			# print("host_choices:$host_choices, removed:$removed\n")
		end
		if win
			if switch
				wins[:switch] += 1
			else
				wins[:stay] += 1
			end
		else
			if switch	
				losses[:switch] += 1
			else
				losses[:stay] += 1
			end
		end
		ran = true
	end
	print("\n")
	print_stats(n_trials, n_doors, n_opens, wins, losses)
end
  ╠═╡ =#

# ╔═╡ a612522a-719c-4b04-9bc6-026531cb1205
md"""
Tests, etc.
"""

# ╔═╡ 53b5fe15-927f-4689-8ef2-5c2d00fa4f08
# ╠═╡ disabled = true
#=╠═╡
# check a morphed set of options. Doesn't work without some globals set
function cklen(a)
	print(sort(a))
	correct = length(zapped)
	@assert length(a) == correct "$(length(a)) != $(correct)\n"
	a
end
  ╠═╡ =#

# ╔═╡ 586a2a12-4a07-4afa-bae9-ef87720620c1
# ╠═╡ disabled = true
#=╠═╡
function zapit(;doors, car, nzap)
	@assert nzap <= doors-2
	zlast = doors - nzap
	if car <= zlast
		a = collect(2:zlast)
	else # car > zlast
		a = cat(2:zlast-1, car, dims=1)
	end
	a
end
  ╠═╡ =#

# ╔═╡ d04b02e8-693e-4f40-a340-a36ea8f4263d
# ╠═╡ disabled = true
#=╠═╡
function tzap(doors)
	full = collect(1:doors)
	after = full[2:end]
	print("after = $(after)\n")
	print("[c,o]\n")
	for nz in 1:doors-2
		zlast = length(full) - nz
		for car in 2:doors
			correct = sort(cat(setdiff(after, car)[1:end-nz],car,dims=1))
			zapped = sort(zapit(doors=doors, car=car, nzap=nz))
			if correct != zapped
				nope = '*'
			else
				nope = ' '
			end
			if car < zlast
				zz = "<"
			elseif car == zlast
				zz = "="
			else
				zz = ">"
			end
			Printf.@printf("[%s,%s]%s: %s%20s %20s\n", car, nz, zz, nope, correct, zapped)
		end
		print("\n")
	end
end
  ╠═╡ =#

# ╔═╡ fb2fcad7-c3bd-43c9-a4a9-125adb256a56
# ╠═╡ show_logs = false
# ╠═╡ disabled = true
#=╠═╡
tzap(3)
  ╠═╡ =#

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Format = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
ProgressLogging = "33c8b6b6-d38a-422a-b730-caa89a2f386c"

[compat]
Format = "~1.3.2"
ProgressLogging = "~0.1.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.0-rc1"
manifest_format = "2.0"
project_hash = "ec66663afab2d7ee45e9e1fd45119896a46b0219"

[[deps.Format]]
git-tree-sha1 = "03bcdf8ab1a5b9e6455ccb45c30910d282aa09f4"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.2"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.ProgressLogging]]
deps = ["Logging", "SHA", "UUIDs"]
git-tree-sha1 = "80d919dee55b9c50e8d9e2da5eeafff3fe58b539"
uuid = "33c8b6b6-d38a-422a-b730-caa89a2f386c"
version = "0.1.4"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
"""

# ╔═╡ Cell order:
# ╟─1f2421cb-9730-4af5-a112-440e681db9c5
# ╟─a43e93b5-8e69-45a1-ad5f-77298b0a3217
# ╠═5363cfdd-63c5-4559-aba2-6ef520dbab12
# ╟─7312b7b0-c023-437f-821e-71eee38da234
# ╠═8cf35575-5e1a-42d3-bc98-930f1d31bbba
# ╟─bc84bb6c-6a34-40db-be89-19145ab01f69
# ╠═31bdb98b-33e5-44be-b35a-7d8d4a7789f1
# ╠═4f3d46be-4d4a-453f-b062-a6afd51b4b33
# ╠═d0c6c99c-74f1-4f6c-a9cf-832da99c6f1e
# ╟─1bf7657d-1886-497a-9d73-a13c443a107d
# ╠═8d94575e-8258-4916-9ef3-dbd99fbb8a1d
# ╟─bcf4d581-eda0-47c3-8c3c-17f00e3ac511
# ╟─5bb70c2f-8d41-453e-9761-2585ec177403
# ╟─3b6add7c-a77c-4786-b4d9-ddee1823bbb0
# ╟─f12a9f27-3ae5-447f-b747-5898596bca96
# ╟─a612522a-719c-4b04-9bc6-026531cb1205
# ╟─53b5fe15-927f-4689-8ef2-5c2d00fa4f08
# ╟─586a2a12-4a07-4afa-bae9-ef87720620c1
# ╟─d04b02e8-693e-4f40-a340-a36ea8f4263d
# ╠═fb2fcad7-c3bd-43c9-a4a9-125adb256a56
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
