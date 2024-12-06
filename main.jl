using JuMP
using Gurobi
using Dates
using CSV, DataFrames
using DateFormats
using Random
using Statistics



# fileCURSUS = "cursus-bacA.csv" # small file
fileCURSUS = "cursusA.csv"


MODE = 0
CANCEL = false



if length(ARGS) < 2
    println("Arguments missing.")
    println("Run as \"julia --project main.jl mode `mode_type`\" ")
    println("Replace `mode_type` for \"1\" if using Gurobi solver; `mode_type` \"2\" if using the heuristics.")
    global CANCEL = true

elseif length(ARGS) == 2
    @assert ARGS[1] == "mode" "It requires command `mode`."
    try
        
        # @assert isdigit(ARGS[2]) "`mode_type` should be an Integer."
        global MODE = parse(Int64, ARGS[2])

        if (MODE < 1 || MODE > 2)
            println("Arguments missing.")
            println("Run as \"julia --project main.jl mode `mode_type`\" ")
            println("Replace `mode_type` for \"1\" if using Gurobi solver; `mode_type` \"2\" if using the heuristics.")
            global CANCEL = true
        end
    catch
        println("Arguments missing.2222")
        println("Run as \"julia --project main.jl mode `mode_type`\" ")
        println("Replace `mode_type` for \"1\" if using Gurobi solver; `mode_type` \"2\" if using the heuristics.")
        global CANCEL = true
    end
else
    @assert ARGS[1] == "mode" "It requires command `mode`."
    println("Arguments missing.")
    println("Run as \"julia --project main.jl mode `mode_type`\" ")
    println("Replace `mode_type` for \"1\" if using Gurobi solver; `mode_type` \"2\" if using the heuristics.")
    global CANCEL = true
end



if !CANCEL

    include("functions.jl")
    
    #Time measure
    start = now()
    println("[Starting..]")

    dbCOURSE = CSV.read(fileCURSUS, DataFrame, delim=";", header=false)
    dbCURSUS = f_read_students(fileCURSUS)

    if MODE == 1
        
        include("model.jl")
        println("\n[Using MIP solver]")
        println("\n- Generating January series.")
        students, student_exams, oral_exams, max_students_per_day, series = f_data_processing(dbCURSUS, "InfoCoursesJan.csv")
        # model ip
        z = ip_model(students, student_exams, oral_exams, max_students_per_day, series)
        dbCOURSE = f_assign_serie(z, students, oral_exams, series, dbCOURSE)

        println("\n- Generating June series.")
        students, student_exams, oral_exams, max_students_per_day, series = f_data_processing(dbCURSUS, "InfoCoursesJune.csv")
        z = ip_model(students, student_exams, oral_exams, max_students_per_day, series)

        dbCOURSE = f_assign_serie(z, students, oral_exams, series, dbCOURSE)

        # Save results to CSV file.
        f_save_csv(fileCURSUS, dbCOURSE, "output/model")

    elseif MODE == 2

        include("heuristic.jl")
        println("\n[Using Heuristic]")
        
        println("\n- Generating January series.")
        students, student_exams, oral_exams, max_students_per_day, series = f_data_processing(dbCURSUS, "InfoCoursesJan.csv")
        final_assignment, final_penalty = simulated_annealing(students, student_exams, series, max_students_per_day)
        println("- Final: ", round(final_penalty, digits=4))
        dbCOURSE = f_assign_serie_h(final_assignment, students, oral_exams, dbCOURSE)

        println("\n- Generating June series.")
        students, student_exams, oral_exams, max_students_per_day, series = f_data_processing(dbCURSUS, "InfoCoursesJune.csv")
        final_assignment, final_penalty = simulated_annealing(students, student_exams, series, max_students_per_day)
        println("- Final: ", round(final_penalty, digits=4))
        dbCOURSE = f_assign_serie_h(final_assignment, students, oral_exams, dbCOURSE)

        # Save results to CSV file.
        f_save_csv(fileCURSUS, dbCOURSE, "output/heuristic")
    end

    


    elapsed = now() - start
    # to improve this output, check url
    # https://stackoverflow.com/questions/52360729/in-julia-convert-elapsed-time-to-hoursminutesseconds
    println("Taken time: ", canonicalize(Dates.CompoundPeriod(elapsed)))

    println("[Finished]")
end 
