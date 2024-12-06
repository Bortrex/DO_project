# TODO: 2speedUp - there are many exams that only has 1 serie. 
# We could simply just ignore those exams and students assigned to them.

# Function to generate an initial random assignment
function f_generate_initial_assignment(students, student_exams, series)

    series_count = Dict()
    for (exam, ex_series) in series
        # filling dictionary
        series_count[exam] = Dict()
        for i in ex_series
            series_count[exam][i] = 0
        end
    end

    assignment = Dict()
    for s in students
        assignment[s] = Dict()
        for e in student_exams[s]
            # available_series = series[e] # all type of series
            # consider only series that are not full
            available_series = [i for i in series[e] if series_count[e][i] < max_students_per_day[e] ]
            assigned_series = rand(available_series)
            assignment[s][e] = assigned_series
            series_count[e][assigned_series] += 1 # update series dict
        end
    end
    return assignment
end

# Function to evaluate the assignment (objective function)
function f_evaluate_assignment(assignment, max_students_per_day)
    penalty = 0
    series_count = Dict()

    for exam in keys(max_students_per_day)
        # filling dictionary
        series_count[exam] = Dict()
        for i in series[exam]
            series_count[exam][i] = 0
        end

        for student in keys(assignment)
            if haskey(assignment[student], exam)
                series_assigned = assignment[student][exam]
                series_count[exam][series_assigned] += 1
            end
        end

        # Penalize for surpassing the max student per oral's exam day
        for i in keys(series_count[exam])
            if series_count[exam][i] > max_students_per_day[exam]
                penalty += series_count[exam][i] - max_students_per_day[exam]
            end
        end

        # Penalize for non-sequential filling
        # The 1st penalizes if sequence is not full
        # The 2nd penalizes if next_series_i is bigger than current
        for i in 1:(length(series[exam]) - 1)
            # if series_count[exam][series[exam][i+1]] > 0 && series_count[exam][series[exam][i]] < max_students_per_day[exam]
            if series_count[exam][series[exam][i]] < series_count[exam][series[exam][i + 1]] # 2nd option
                penalty += max_students_per_day[exam] - series_count[exam][series[exam][i]]
            end
        end

        # Penalize for non-homogeneity
        counts = collect(values(series_count[exam]))
        # std_counts = std(counts .^ 2)        
        # penalty += isnan(std_counts) ? 0.0 : std_counts
        sum_counts = sum(counts .^ 2)
        penalty += sum_counts

    end
    return penalty
end

# Function to perform simulated annealing
function simulated_annealing(students, student_exams, series, max_students_per_day, max_iterations=8700, initial_temp=100.0, cooling_rate=0.9992)
    current_assignment = f_generate_initial_assignment(students, student_exams, series)
    current_penalty = f_evaluate_assignment(current_assignment, max_students_per_day)
    println("\nPenalty:\n- Initial: $(round(current_penalty, digits=4))")
    
    best_assignment = deepcopy(current_assignment)
    best_penalty = current_penalty
    temperature = initial_temp
    
    for it in 1:max_iterations
        # Generate a neighbor solution
        new_assignment = deepcopy(current_assignment)
        student = rand(students)
        # all oral exams from the student are reviewed
        # TODO: make a memory? to keep track of `new_assignments`. :/ 
        exam = rand(student_exams[student]) 

        available_series = series[exam]
        new_series = rand(available_series)
        new_assignment[student][exam] = new_series
        
        # Evaluate the new solution
        new_penalty = f_evaluate_assignment(new_assignment, max_students_per_day)
        
        # Calculate the acceptance probability
        acceptance_probability = exp((current_penalty - new_penalty) / temperature)
        
        # Update penalty OR Accept the new solution with a certain probability
        if new_penalty < current_penalty || rand() < acceptance_probability
            current_assignment = new_assignment
            current_penalty = new_penalty
            if current_penalty < best_penalty
                best_assignment = deepcopy(current_assignment)
                best_penalty = current_penalty
            end
        end
        
        # Cool down the temperature
        temperature *= cooling_rate
    end
    
    return best_assignment, best_penalty
end