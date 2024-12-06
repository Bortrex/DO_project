# Discrete Optimization project

The problem is related with the scheduling of exams in order
to obtain the best possible schedule for the students.

## Procedure

Please read *section 1 - Series assigment* in `statement.pdf` file.

## Results

| Session   | **IP Model**              |              | **Heuristic**            |                |
|-----------|---------------------------:|---------------:|---------------------------:|----------------:|
|           | **Objective Function**          | **Time**          |**Objective Function**      | **Time**           |
| January   | 13501                    | ~14s          | ~13503                   | ~52s           |
| June      | 58859                    | ~16s          | ~58863                   | ~1m19s         |
| **Total** | **72360**                | **~26s**      | **~72365**               | **~1m55s**     |

**Note:** To consider that reading and pre-processing the data takes around 9 seconds.


### Integer Programming Model

The model follows all the formulation described in `report.pdf` file. Please, check it for details.

This model provides the following schedule:

<img src="https://github.com/user-attachments/assets/8ee423ee-ca62-4fff-a17e-d4066f110ff7" width="800" height="500">

### Heuristic

Simulated annealing - It is a metaheuristic based on local search algorithm that tries to escape from local minima.
The heuristic provides a similar result to IP model.

<img src="https://github.com/user-attachments/assets/fafbf267-f491-45eb-9085-32582dc03e34" width="800" height="500">

###### Initial attempts

This graph is the initial result of our IP model implementation. To denote how the series *SX* were randomly filled to their maximum.

<img src="https://github.com/user-attachments/assets/253d14d7-9118-43bc-81e8-ffc21a8fb600" width="500" height="300">

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Authors

– [@Bortrex](https://github.com/Bortrex)
