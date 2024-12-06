function ip_model(students, student_exams, oral_exams, max_students_per_day, series)
    # Create the model
    model = Model(Gurobi.Optimizer)

    # Decision variable
    @variable(model, z[s in students, e in oral_exams, i in series[e]] , Bin)
    @variable(model, max_stu_in_serie_exam[e in oral_exams, i in series[e]], Int)

    # Constraints 1
    # Each student must be assigned to one series of oral exam they are taking.
    for s in students
        for e in student_exams[s]
            @constraint(model, sum(z[s, e, i] for i in series[e]) == 1)
        end
    end

    # Constraints 2
    # Ensure students are not assigned to series for exams they are not taking.
    for s in students
        for e in oral_exams
            if !(e in student_exams[s]) # not in the list of student's oral exam.
                for i in series[e]
                    @constraint(model, z[s, e, i] == 0)
                end
            end
        end
    end

    # Constraints 3
    # Capacity constraint for each series of oral exam.
    for e in oral_exams
        for i in series[e]
            @constraint(model, sum(z[s, e, i] for s in students) <= max_students_per_day[e])
        end
    end

    # Constraint 4
    # Capacity constraint for maximum students per serie
    for e in oral_exams
        for i in series[e]
            @constraint(model, sum(z[s, e, i] for s in students) <= max_stu_in_serie_exam[e, i])
        end
    end

    # Constraint 5
    # Filling first series sequentially
    for e in oral_exams
        for i in 1:(length(series[e])-1)
            @constraint(model, max_stu_in_serie_exam[e, series[e][i]] >= max_stu_in_serie_exam[e, series[e][i+1]])
        end
    end

    @objective(model, Min, sum(sum(max_stu_in_serie_exam[e, i]^2 for i in series[e]) for e in oral_exams))

    # Solve the model
    optimize!(model)
    
    if !is_solved_and_feasible(model; dual = false)
        error(
            """
            The model was not solved correctly:
            termination_status : $(termination_status(model))
            primal_status      : $(primal_status(model))
            dual_status        : $(dual_status(model))
            raw_status         : $(raw_status(model))
            """,
        )
    end
    
    println("  objective value = ", objective_value(model))
    return z
end


# function ip_model(students, student_exams, oral_exams, max_students_per_day, series)
#     # Create the model
#     model = Model(Gurobi.Optimizer)

#     # Decision variable
#     @variable(model, z[s in students, e in oral_exams, i in series[e]], Bin)

#     # Constraints 1
#     # Each student must be assigned to one series of oral exam they are taking.
#     for s in students
#         for e in student_exams[s]
#             # if e in oral_exams
#                 @constraint(model, sum(z[s, e, i] for i in series[e]) == 1)
#             # end
#         end
#     end

#     # Constraints 2
#     # Ensure students are not assigned to series for exams they are not taking.
#     for s in students
#         for e in oral_exams
#             if !(e in student_exams[s]) # not in the list of student's oral exam.
#                 for i in series[e]
#                     @constraint(model, z[s, e, i] == 0)
#                 end
#             end
#         end
#     end

#     # Constraints 3
#     # Capacity constraint for each series of oral exam.
#     for e in oral_exams
#         for i in series[e]
#             @constraint(model, sum(z[s, e, i] for s in students) <= max_students_per_day[e])
#         end
#     end

#     # Objective function
#     @objective(model, Min, sum((sum(z[s, e, i] for s in students) - length(students) / length(series[e]))^2 
#                             for e in oral_exams for i in series[e]))

#     # Solve the model
#     optimize!(model)
#     if !is_solved_and_feasible(model; dual = false)
#         error(
#             """
#             The model was not solved correctly:
#             termination_status : $(termination_status(model))
#             primal_status      : $(primal_status(model))
#             dual_status        : $(dual_status(model))
#             raw_status         : $(raw_status(model))
#             """,
#         )
#     end
#     println("  objective value = ", objective_value(model))
#     return z
# end