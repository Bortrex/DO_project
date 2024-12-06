function f_add_examType(df, writtenExams, oralExams)

    # We use all the exams present in `cursus` file. Meaning only matches between `cursus` & `infoCourses`
    # makeunique is necessary as columns names between DFrames are not unique!
    # leftjoin to keep size of db1 | innerjoin to keep only all matches | rightjoin keep size of db2 | outerjoin keep all
    df = leftjoin(df, oralExams, on = :Column2 => :Column1 , makeunique=true, order=:left)
    df = leftjoin(df, writtenExams, on = :Column2 => :Column1 , makeunique=true, order=:left)

    # Update Column4_1 with the information from ExamType
    for row in eachrow(df)
        if ismissing(row.Column4_1) && !ismissing(row.Column4_2)
            row.Column4_1 = row.Column4_2
        end
    end

    # Rename columns for clarity
    rename!(df, Dict(:Column1 => :StudentID, :Column2 => :CourseID, :Column4_1 => :ExamType))
    # Drop last column & students with no exam 
    select!(df, Not(:Column4_2))
    dropmissing!(df, :ExamType)
    return df
end

function f_daysSet(weeks=4)
    
    # Define the days of the week excluding Sundays
    days_of_week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    # Create an array to hold the days and their indices
    days = []
    indices = []

    # Generate the days and indices for X weeks
    for week in 1:weeks
        for (i, day) in enumerate(days_of_week)
            push!(days, day)
            push!(indices, (week - 1) * length(days_of_week) + i)
        end
    end  

    # return the DataFrame
    return DataFrame(day = days, day_index = indices)
end


function f_calculate_series(count, max_students)
    # Calculate the number of sessions per exam given its maximum
    if max_students == "all"
        return 1
    else
        return ceil(Int, count / parse(Int, max_students))
    end
end


function f_assign_serie(z, students, oral, series, dfStudents)
    counter = 0

    for s in students
        for e in oral
            # if e in student_exams[s] # conditional to limit exams
                for i in series[e]
                    if value(z[s, e, i]) > 0.5
                        # println("Student $s is assigned to series $i for exam $e$i")
                        cond1 = dfStudents.Column1 .== s
                        cond2 = dfStudents.Column2 .== e
                        # cond1 = dfStudents.StudentID .== s
                        # cond2 = dfStudents.CourseID .== e
                        comb_cond = cond1 .&& cond2
                        dfStudents[comb_cond, :Column2] .= "$e$i"
                        # dfStudents[comb_cond, :CourseID] .= "$e$i"
                        counter += 1
                    end
                end
            # end
        end
    end
    println("Counter: $counter")
    return dfStudents
end

function f_assign_serie_h(z, students, oral, dfStudents) 
    for s in students
        for e in oral
            if e in student_exams[s] # conditional to limit exams
                        
                cond1 = dfStudents.Column1 .== s
                cond2 = dfStudents.Column2 .== e
                i = z[s][e]
                comb_cond = cond1 .&& cond2
                dfStudents[comb_cond, :Column2] .= "$e$i"
                # println("Student $s is assigned to series $i for exam $e$i")
            end
        end
    end
    return dfStudents
end

function f_save_csv(name, db, folder="output",  header=false, sep=";")
    # Give a DataFrame to save it in a given folder
    dirName = joinpath(@__DIR__, folder)
    if !ispath(dirName)
        mkpath(dirName)
    end

    CSV.write(joinpath(folder, name), db, header=header, delim=sep)
end

function f_read_students(fileStudents)
    println("Total number of courses: ")
    dbCOURSE = CSV.read(fileStudents, DataFrame, delim=";", header=false)
    dbCURSUS = dropmissing(dbCOURSE, :Column4) # dropping courses not assigned to acadamic calendar

    dbCURSUSjan = dbCURSUS[dbCURSUS."Column4" .== "Q1", :]
    dbCURSUSjun = dbCURSUS[dbCURSUS."Column4" .== "Q2", :]
    dbCURSUSta = dbCURSUS[dbCURSUS."Column4" .== "TA", :] # all year round # no exams at all
    println("- Courses in Jan $(size(dbCURSUSjan, 1)). ")
    println("- Courses in Jun $(size(dbCURSUSjun, 1)). ")
    println("- Courses in All Year $(size(dbCURSUSta, 1)). ")
    return dbCURSUS
end


function f_data_processing(dbCURSUS, fileInfoCourses)
    """
    Function reads student and course data from the CSV files, processes the data to filter and clean it. 
    It handles missing values and calculates the number of sessions for each exam. 
    The function returns essential information needed for further scheduling tasks.
    
    Returns
        - `students::Vector{String}`: A vector of student IDs.
        - `student_exams::Dict{String, Vector{String}}`: A dict mapping student IDs to their corresponding course IDs.
        - `oral_exams::Vector{String}`: A vector of course IDs that have oral exams.
        - `max_students_per_day::Dict{String, Int}`: A dict mapping course IDs to the maximum number of students per session.
        - `series::Dict{String, Vector{String}}`: A dict mapping course IDs to the series (sessions) of the exams.

        """

    dbINFOcu = CSV.read(fileInfoCourses, DataFrame, delim=";", header=false)
    replace!(dbINFOcu.Column5, "tous" => "all") # internal modification

    # 'no exam' tag was excluded
    uqINFO = unique(dbINFOcu)
    dbINFOoral = uqINFO[uqINFO."Column4" .== "oral", :] # all oral exams
    replace!(dbINFOoral.Column5, missing => "24") # internal modification
    oralTag = select(uqINFO[uqINFO."Column4" .== "oral", :], [:Column1, :Column4])
    writtenTag = select(uqINFO[uqINFO."Column4" .== "written", :], [:Column1, :Column4])

    dbCURSUS = f_add_examType(dbCURSUS, writtenTag, oralTag)
    # Set of students having Oral Exams
    # E : Set of exams
    # - Set of Oral exams
    # O C E : Set of oral exams
    studentsOralEx = filter(row -> !ismissing(row.ExamType) && row.ExamType == "oral" , dbCURSUS ) 
    examsStudent = combine(groupby(studentsOralEx, :StudentID), :CourseID => (x -> [x]) => :CourseIDs)

    oralExams = combine(groupby(studentsOralEx, :CourseID), nrow => :Count)
    oralExams = leftjoin(oralExams, dbINFOoral, on = :CourseID => :Column1 , makeunique=true, order=:left)
    select!(oralExams, Not(:Column2, :Column3))
    # Calculate the number of series for each exam
    oralExams[!, :Series] = [f_calculate_series(row.Count, row.Column5) for row in eachrow(oralExams)]
    
    # Create a dict for series each oral exam has
    series = Dict(
    row.CourseID => ["S$i" for i in 1:row.Series]

    for row in eachrow(oralExams)
    )
    # Create a dict for maximum students per day each oral exam has
    max_students_per_day = Dict( # default limit is set to 24 students
        row.CourseID => row.Column5 != "all" ? parse(Int, row.Column5) : 24 
        for row in eachrow(oralExams)
    )
    # Create a dict for exams each student is taking
    student_exams = Dict(
        row.StudentID => row.CourseIDs
        for row in eachrow(examsStudent)
    )
    # Extract the list of oral exams and students
    oral_exams = oralExams.CourseID
    students =  examsStudent.StudentID 

    return students, student_exams, oral_exams, max_students_per_day, series
end
