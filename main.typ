#import "template.typ": *

// Take a look at the file `template.typ` in the file panel
// to customize this template and discover how it works.
#show: project.with(
  title: "Hybrid Black-box and model based optimization",
  authors: (
    "Kevin Yu",
  ),
)

#show figure: it => align(left)[
  #it.body
  #emph[
    Figure
    #it.counter.display(it.numbering)
  ] | 
  #it.caption
  #v(10pt, weak: true)
]

#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
)


// We generated the example code below so you can see how
// your document will look. Go ahead and replace it with
// your own content!

= Introduction
Optimization problems can be found in many disciplines, such as business, engineering, and biology. Some of these problems can be modelled using formal methods or computer languages, while the inner workings of others are too complex or unknown to be modelled. 
At the intersection, there are hybrid problems that possess both modellable and Black-Box components.

While there has been extensive research into approaches to solving both kinds of problems individually, there has not been much investigation into effective techniques to optimize problems that lie at this intersection.

Hence, the question that this literature review seeks to explore, and the research project to answer is: 

Are there effective ways to combine the approaches to model-based and black-box optimization, to solve problems that are a hybrid of modellable and Black-Box ? 

=== Introduction to modellable problems

As a motivating example, a classic modellable optimization problem is the nurse scheduling problem. 

This problem consists of assigning a number of nurses to a number of shifts over a time period, and also subject to constraints such as nurses required per shift and each nurse's availability. @google
- Each day is divided into 3, 8 hour shifts; a day, evening and night shift
- Each day, every shift is assigned to a single nurse, and no nurse works more than one shift per day
- We want to make the shift distribution as equal as possible.

One way to solve this problem is to define a model, and let backend solvers solve the problem:

#figure(
```Python 
int: numNurses = 4;
int: numDays = 3;
int: numShifts = 3;
set of int: allNurses = 1..numNurses;
set of int: allDays = 1..numDays;
set of int: allShifts = 1..numShifts;

array[allNurses, allDays, allShifts] of var bool: roster;

constraint forall(d in allDays, s in allShifts)(
  let {var int: sm = sum(i in allNurses)(roster[i,d,s]);}
    in sm = 1
);

constraint forall(n in allNurses, d in allDays)(
  let {var int: sm = sum(i in allShifts)(roster[n,d,i]);}
    in sm <= 1
);

constraint forall(n in allNurses)(
  let {var int: sm = sum(d in allDays, s in allShifts)(roster[n,d,s]);
  } in sm >= minShiftsPerNurse /\ sm <= maxShiftsPerNurse
);
solve satisfy;
```,
caption: "A MiniZinc model for the nurse scheduling problem (Note that some parts of code have been omitted for brevity)"
)

When run with the output code (omitted), the following would be outputted:
#figure(
  ```Python
  Nurse 1 works shifts: 3 on day 1; 2 on day 2; 3 on day 3; 
  Nurse 2 works shifts: 2 on day 1; 1 on day 2; 
  Nurse 3 works shifts: 3 on day 2; 1 on day 3; 
  Nurse 4 works shifts: 1 on day 1; 2 on day 3;
  ```, caption: "Output of the nurse scheduling problem in MiniZinc"
)

In figure 2:
- 1 is a morning shift
- 2 is an evening shift
- 3 is a night shift

=== Introduction to unmodellable, Black Box problems
An example of an unmodellable problem is traffic light scheduling based on real world data @traffic. Within a road network, this problem aims to optimize the light cycle programs of traffic lights, to improve traffic flow and reduce pollution. As this problem involves a large volume of data and many variables, such as each individual moving car, it cannot be adequately modelled.

Instead, problems like traffic light scheduling using real world data often resort to simulation @traffic_2. Given some input such as each car's starting position and path, as well as the traffic light cycle program, it will output data on the performance of the simulation. Output data can include values such as the number of vehicles that reach their final destination, or the total travel time and waiting time for vehicles that complete their journey. These values are all valid candidates for optimization. The simulation function can be thought of as a Black Box function that can be optimized on its output variables.

=== Introduction to hybrid problems
At the intersection of modellable and unmodellable problems, there are hybrid problems. Usually, there are extensions of unmodellable black-box problems, where the constraints of the input to the problem can be reliably modelled. For example, in the above traffic light simulation problem, a constraint that can be introduced, is that the total wait time of any car should not exceed more than $s$ seconds.

The following literature reivew will include:
- A background on combinatorial satisfaction problems and constraint optimization problems
- A background on modellable, unmodellable and hybrid problems
- Black-Box problems
- Approaches to Black-Box Optimization
- Hybrid approaches to optimization
// Ask yourself:
// At the end of this:
// - what are people going to get out of this/why is this important?
// - why is this problem interesting?
#pagebreak()

= Substantive Literature Review
= Background
This section will introduce some concepts and definitions that will be referred to within this literature review.

== Combinatorial satisfaction problems (CSP)
Each optimization problem can be built upon a base combinatorial satisfaction problem, therefore we will first define this.
A combinatorial satisfaction problem is defined as a triple $(X, D, C)$ where:
- X = {X#sub[1],...,X#sub[n]} is a set of variables (also known as decision variables)
- D = {D#sub[1],...,D#sub[n]} is a set of domains for each variable in X
- C = {C#sub[1],...,C#sub[n]} is a set of constraints, where each constraint $C#sub[i]$ is a relation defined over a subset of X, specifying a set of allowable combinations of values for the variables.

$bold("Definitions")$

- Assignment: A mapping of variables to their individual values
- Candidate solution: An assignment such that each variable X#sub[i] lies within its corresponding domain D#sub[i]
- Search space: The set of all candidate solutions
- Solution: A solution such that all constraints in C are satisfied

When there is at least one solution to a CSP, the CSP can be described as _feasible_. If not, then it is _infeasible_

== Constraint optimization problems (COP)
A combinatorial satisfaction problem can be extended to be a combinatorial optimization problem by adding an objective function, that has input the set $X$ of constraints (with domain $D$) and outputs a real value, known as the cost, or score.

Formally, an optimization problem can be defined as:
#set align(start)

#grid(columns: (100pt, 1fr), rows: 14pt, column-gutter: 8pt,
                    align(start)[
                      $"minimize"$
                    ],
                    align(start)[$f(x)$],
                    align(start)[
                      $"subject to"$
                    ],
                    align(start)[
                      $g#sub[i]"(x)" <= 0$, i = 1,...,m
                    ],
                    align(center)[],
                    align(start)[
                      $h#sub[j]"(x)" = 0$, j = 1,...,n
                    ])

#set align(left)
where 

- $f: RR^n -> RR "is the objective function to be minimized"$
- $x in Omega subset RR^n, "the parameter domain, where n is the number of parameters"$
- $g#sub[i]"(x)" <= 0$ are inequality constraints
- $h#sub[j]"(x)" = 0$ are equality constraints
- $m >= 0 "and" p >= 0$

The above definition applies to both minimization and maximization problems, as a maximization problem can always be transformed into a minimization problem by negating the entire objective function.

#set align(left)

== Modellable problems
For problems that have an explicit problem formulation, modelling can be done using computer software or modelling languages.  Modelling on software such as Matlab @matlab or MiniZinc @minizincc encapsulates the problem itself; rather than describing _how_ exactly to solve the problem, it describes _what_ the problem is. This description can then be sent to a backend solver which can find a solution. This is in contrast to traditional methods where a specific imperative algorithm is devised to solve a problem. 

To demonstrate its capabilities, here is an example taken from the MiniZinc Handbook @minizinc_handbook; imagine the scenario where we need to bake some cakes for a fete. We can make two sorts of cakes: A banana cake which takes 250g of self-raising flour, 2 mashed bananas, 75g sugar and 100g of butter, and a chocolate cake which takes 200g of self-raising flour, 75g of cocoa, 150g sugar and 150g of butter. We can sell a chocolate cake for \$4.50 and a banana cake for \$4.00. And we have 4kg self-raising flour, 6 bananas, 2kg of sugar, 500g of butter and 500g of cocoa. The question is how many of each sort of cake should we bake for the fete to maximize the profit.

On one hand, we can devise an algorithm to solve this problem. This problem can be solved using the Simplex algorithm, however this would be fairly involved, as one would have to know the algorithm, its caveats, as well as implement it.

On the other hand, we can simply model the problem as it is, and allow one of many backend solvers to solve the problem for us. This enables us to focus on defining the problem, rather than coming up with solutions to it. See below for a model of this problem in the Constraint Programming modelling language MiniZinc.


#figure(
```Python 
% Baking cakes for the school fete

var 0..100: b; % no. of banana cakes
var 0..100: c; % no. of chocolate cakes

% flour
constraint 250*b + 200*c <= 4000;
% bananas
constraint 2*b  <= 6;
% sugar
constraint 75*b + 150*c <= 2000;
% butter
constraint 100*b + 150*c <= 500;
% cocoa
constraint 75*c <= 500;

% maximize our profit
solve maximize 400*b + 450*c;

output ["no. of banana cakes = \(b)\n",
         "no. of chocolate cakes = \(c)\n"];
```,
caption: "A MiniZinc model for the school fete problem"
)

The MiniZinc model in figure 3 mirrors the definition of a COP as defined above:
- The parameter domain in the COP definition is equivalent to the ```Python var 0..100: b; ``` variable declarations
- The constraints in the COP definition is equivalent to the ```Python constraint``` declarations
- The objective function is equivalent to the ```Python solve maximize 400*b + 450*c``` declaration

// TODO: Could go more in detail about MiniZinc ? 
=== Introduction to optimization paradigms and modelling languages
There are many paradigms for optimization, such as constraint programming, integer programming, or satisfaction solving. Each technique is suited to its own type of problem. For example, constraint programming is suited to CSP problems while integer programming is suited to COPs where constraints and objective function are linear. Each optimization technique also has many solvers, which take as input a model written in the solver's language or library. Constraint programming has libraries such as Gecode, where models can be written in C++, with the use of Gecode's library, while Integer Programming has GLPK, where the MathProg language must be used.


While there are many approaches to model based optimization, in this literature review we will be focusing on constraint programming in particular. This firstly due to its flexibility, being able to model a variety of combinatorial optimization and satisfaction problems. Further, there is a mature and robust constraint modelling language - MiniZinc @nethercode_2007 which we can extend to conduct our research. More justification as to why MiniZinc was chosen will be provided in the following sections.

=== Introduction to constraint programming
In constraint programming, also known as constraint optimization, the user models the problem by defining the decision variables, their domains, and then stating the constraints on decision variables. 
Constraint Programming approaches are adept at solving CSPs such as the N-Queens problem, since they directly work to resolve constraints on the problem. However, as a CSP can easily be extended to become a COP by adding an objective function, constraint programming can also be extended to solve problems within this domain. 
A simple way to do this is to evaluate the objective function at each solution in the search space and track the solutions which produce the minimum objective function value. 
Constraint problems are usually solved via complete search, with the aid of backtracking and constraint propagation to make the search more efficient.  
Note that complete search doesn't not mean exploring the entire search space, rather that that the solution produced by the solver is _provably_ optimal, as often suboptimal areas of the search space can be logically removed.

// TODO: Could talk a bit about branch and bound
// TODO: Could go more in depth about how constraint programming actually works here?

=== MiniZinc @minizincc
MiniZinc enables users to model problems in a constraint programming paradigm, by defining the decision variables, domains, constraints. Solutions can then be found to either satisfy the model, or optimize it if an objective function is further supplied.

MiniZinc is different to the aforementioned modelling languages as it is _solver independent_ - A single MiniZinc model can be mapped and solved by multiple different solvers, such as Gecode, or OR-Tools (An Integer Programming solver). This allows much more flexibility to test out different solving techniques for a given model, without having to rewrite the problem in each solver's unique language/library. To map to different solvers, MiniZinc first compiles the model into a _FlatZinc_ file, which is then passed to a solver via a solver specific _backend_.

== Unmodellable problems - Black-Box Functions
In contrast, for a Black-Box problem, the nature of f or the domain of $x$ is difficult or impossible to exploit. 
Most commonly, such Black-Box functions are found in computer simulations of complex real world scenarios.

== Hybrid Black-Box and Modellable problems
At the intersection of these two types of problems are hybrid Black-Box and modellable problems. 
In such problems, the decision variables and their constraints can be modelled, but the internals remain a Black-Box function. 
This literature review aims to explore current model based optimization and black-box based optimization approaches, and how the merits of each can potentially be used to solve the problems at this intersection.

== Black-Box problems
The main problems we aim to solve in this study are Black-Box problems with constraints that can be modelled. Some common areas where Black-Box problems arise are:
- Simulations of complex real world scenarios
- Optimization of hyper-parameters in Machine Learning research
- Assembly code

In the following section, we will be examining simulation based Black-Box problems by example.

=== Simulations of complex real world scenarios

In optimization of real world processes, simulations are used to analyze the scenario under different input variables. 

A prominent example is Wind Farm Layout Optimization (WFLOP). This involves positioning wind turbines optimally within a designated wind farm area. The difficulty of this problem arises due to the "wake" of turbulence that individual turbines create, which reduces the wind speed, and consequently energy production of those turbines that are positioned downstream. @samorani_2013

From this scenario, a simplified version of this optimization problem can be formulated as follows; given an amount of farmland, and for a set of positions; the wind speed, direction and probability of this combination occurring, as well as the mathematical models for wake and related physical phenomena, determine an optimal positioning of Wind Turbines to maximize the power output of the wind farm.

Due to the complex relationship between turbines and physical forces, as well as the mathematical models involved in calculating an individual turbine's power output, the actual problem can only be represented through simulation. The representative Black-Box function is one where the inputs are the positions of each individual wind turbine, and the output is a measure of the power output that is produced by the wind farm in this particular arrangement.

In the formulation of this problem as described above, there are several constraints that come into play. The first constraint is that the turbines must lie within the area of the farm.@wagner_2013 For a rectangular farm with length l and width w this constraint can be modelled as:

#set align(center)
$0 <= x#sub("i") <= l and 0 <= y#sub("i") <= w, forall "i"$
#set align(left)

The second constraint that must be taken into consideration is that any two turbines must not be within a certain distance MR of each other, where $"M"$ is a proximity factor and $"R"$ is the rotor radius:

#set align(center)
$sqrt((x#sub("i") - x#sub("j"))^2 + (y#sub("i") - y#sub("j"))^2) >= "MR," forall "i" forall "j"$
#set align(left)

In real scenarios these two constraints are usually known and modellable. As the cost of simulation is high and there is usually an imposed limit on the number of simulations that can be made, WFLOP optimization algorithms aim to guarantee that solutions sent to the simulator are valid, rather than have the simulator report that the solution is infeasible. 

This is either done by introducing a feasibility check in the objective function evaluation routine as seen for Genetic algorithms and Simulated annealing approaches in @samorani_2013, or during the neighbor finding phase in local search techniques explored in @wagner_2013. 

Some approaches described in @samorani_2013 use a discrete solution space - turbines can only be placed at specific points on a grid. This is an example of how constraints can be embedded into the problem formulation itself, such that they do not need to be explicitly dealt with. This however, does have some drawbacks. Since the positioning of each turbine is being restricted, many potentially better solutions are not considered.

Additionally, the WFLOP can be extended to be more realistic by adding more constraints. Current works do not factor in the installation phase, such as the roads (or lack thereof) connecting turbines which are used to transport construction material @samorani_2013. If there are no roads between two turbines, they will need to be built at an additional cost, and the roads that can be built also often carry additional constraints, for example that they must be built along crop boundaries. Therefore another objective that can be formulated is to build a connected network of roads between turbines, subject to constraints and while minimizing the cost of building roads. In this way, the wind farm problem can extended to a multi-objective optimization problem, where we are trying to maximize both the placement of the wind turbines (a Black-Box function), and minimize the cost of building roads between the turbines during construction (a problem that can be adequately modelled).  



== Approaches to Black-Box Optimization
On large and complex Black-Box problems, a complete search of the entire search space is simply impractical, often requiring too much compute and/or time. Therefore the focus of many Black-Box optimization techniques becomes to find a good enough solution in a reasonable amount of time/resources. Many Black-Box optimization techniques cannot provably consider the entire search space, and therefore cannot guarantee optimality.

There are numerous approaches to Black-Box Optimization, such as direct search and hybrid optimization. In the following section we will examine local search, and some heuristic optimization methods.

== Local Search methods
Local search is an optimization technique that is used to find a solution to a problem by exploring the solution space, iteratively improving a candidate solution. 
In local search, a starting solution $s$ is chosen. At each step, the neighborhood of $s$ is considered. 
From this neighborhood, a new solution $s'$ is considered. It is accepted if it improves the objective function. This process continues until no further improvement can be made, or until a stopping condition is met. 

A _heuristic_ is utilized by a local search method to select a neighborhood of the current solution. 
In general, the neighborhood selection is a tradeoff between _exploration_ and _exploitation_. 

_Exploration_ is defined as the ability to reach and test candidate solutions that are outside the local neighborhood of the current solution. This helps the algorithm escape from local minima. _Metaheuristics_ are defined as techniques to escape these local minima. 

_Exploitation_ is defined as the ability to search in the local neighborhood of the current solution. This is done to refine the solution to the local minima. 


=== Simulated Annealing @kirkpatrick_1983
A popular meta-heuristic used in local search is Simulated Annealing.
In each move, a neighbor $s'$ is chosen at random, and we make the move to $s'$ with a certain probability. The probability is 1 if $s'$ is better, and less than one if the move is inferior. This probability depends on T, which is temperature. At the start when the temperature is high, it is more likely that worse solutions are chosen. The temperature is gradually lowered, and consequently the probability of choosing worse solutions is also lowered. Towards the end, solutions chosen are almost always improving ones.

Can frame them as closely related search
The techniques for black box are used with modellable AI. Its hybrid in that its local search with modellable.
Its not hybrid as in black box with modellable, which is what we want.

// Local search you can do in any function
// Talk about how this functions in Black Box.

// For modellable, its not that it hasn't tried to use similar techniques to black-box, the hybrid is the trials where the model is too big, use local search, but do local search where you can design the search (LNS), or generate local search using constraints.

// For black-box, can we use a hybrid. Models, where some of the constraints are unknown, what solving methods work well? As an indication, we probably want to use the hybrids that are already out there.

#pagebreak()
== Hybrid model and local search based approaches to optimization
Since model and local search based approaches to optimization both have their strengths and weaknesses, attempts have been made to combine them both in order to use the strengths of one paradigm to improve upon the weaknesses of the other, and vice-versa.

=== Large neighborhood Search (LNS) @shaw_1998
Large neighborhood search was one of the first techniques combining complete search techniques like constraint programming with local search based methods. The pseudocode for a simple LNS formulation is as follows:

1. Start with a feasible solution (using Constraint Programming)
2. Select a neighborhood (using Local Search)
3. Optimize within the neighborhood (using Constraint Programming)
4. Repeat from step 2 until end condition is met

The above process utilizes the strengths of each type of search technique. Since Constraint Programming is good at finding feasible solutions, is it used to find the initial solution. 

In comparison to complete search techniques, Local Search is more suited to exploring the solution space, so it is used in the algorithm to find a suitable neighborhood to exploit. A neighborhood is chosen by fixing a subset of the variables, and this choice of subset is often problem-specific. 

Choosing a neighborhood constricts the search space to a manageable size so that constraint programming can then be used to optimize the unset variables. This makes use of the fact that given a small enough search space, constraint programming is much better at finding the optimal solution, since it can guarantee optimality, as compared to local search.



=== Constraint Based Local Search (CBLS) @cbls_2005
Constraint based local search is a variation on local search that adapts ideas from CP. Similar to constraint programming, the constraints on the problem are used to guide the local search towards an satisfactory solution. Like in other variants of local search, the search still starts with a configuration which may or may not satisfy the constraints. The algorithm at each iteration identifies the violated constraints, and variables causing the most violations, and forms a neighborhood from this. It then chooses the neighboring solution that leads to the greatest reduction in constraint violations.

While the current solution is in a non-satisfying state, the algorithm will follow these steps to search for a satisfying state:
1. Calculate the constraint violations that each variable creates
2. Pick the variable x (that is not in the tabu list) that is contributing the most to the constraint violations
3. Set all variables except x, forming the neighborhood
4. Calculate the degree constraint violations at each neighbor. If a better one is found, then move to this neighbor. 
If there is no better assignment, then add x to the tabu

This is continued until a satisfying solution is found, or until a maximum number of iterations is reached.

Note that the quantification of violation contribution depends on the type of constraint being violated. For example, for an equality constraint, the amount is $abs(x#sub[1] - c#sub[1])$ where the constraint is $x=c$. Therefore, the further away the variable x is from what it should be, c, the more likely it is that x will be chosen to be re-assigned.

#pagebreak()

= Topics that haven't been touched upon which we discussed

== Hybrid  search method implementations
In CP:
White box - instruct how things are done
Black box - give it something, and get something in return, same thing for search


== Ways in which the black box function can be used
- Could have a black box that is a constraint?
  - When we have a simulation, we might want to make sure that all cars never have to wait more than 5 minutes
  - This is a black box function constraint
- Could do surrogate model
- Look at MiniZinc with functions
  - What will happen when we do that with Black Boxes. 
- Learning solvers, works similar to branch and bound. 

- Give the solver relations between inputs and outputs, could build an approximation that is useful for the solver, if that eliminates some of the solutions I have to try, might be useful. e.g monotonicity. So this is when we know a bit about the shape of the grey box function, we can then use those relations.

- Genetic algorithms
- Talking more about the strengths and weaknesses of each heuristic algorithm

= Summary of the State of the Art
The literature review has explored many techniques to solve modellable problems, such as constraint programming, as well as many techniques for solving Black-Box problems, such as local search. We have also seen many hybrid approaches to solving modellable problems that incorporate the strengths of each approach. 

It is evident that the combination of two approaches is an effective way to improve an algorithm's approach. 

However, these hybrid approaches are designed largely for problems which can be reliably modelled. For example, LNS is largely used in transportation optimization problems where the different stops on a path are known beforehand. Further research can explore ways to utilize LNS in Black Box problems like simulation.

Furthermore, current research on Black Box problems largely focuses on the Black Box being the function being optimized. Further research can examine scenarios where the constraints of the function are actually Black Box functions, and how this can be effectively solved via optimization methods.


While the intersection of modellable and black box functions presents a clear gap in research, we potentially lack the necessary technology to investigate this problem. A review of the literature also suggests many solvers only support one paradigm or the other; either they are suited towards modellable problems, or Black Box problems. Therefore, in order to conduct our research, we need to extend an existing technology to support this use case.

With MiniZinc, a way to extend this generality would be to introduce BlackBox function evaluation. This can be done for the objective function values, and potentially the constraints as well (as there can be Black Box constraints). As MiniZinc is easily extendable through annotations, this is something that can easily be achieved. Previous research has also modified MiniZinc to provide proof of concept of various solving techniques, so it would be an ideal candidate. The implementation for this functionality would largely have to be handled at the solver level, since the solver would need to evaluate the Black Box function when it would usually evaluate the objective function. Integrating with MiniZinc would also have the added benefit in that it already supports many different solvers. One in particular - Gecode, has been extended in previous studies to allow for meta-heuristic search, instead of the usual complete search methods. This would allow for testing of hybrid approaches, on Black Box functions and constraints.

Furthermore, research does suggest that in Grey Box optimization problems where the shape of the function is known, this knowledge can be exploited during the optimization process. However, many solutions for this type of grey box problem algorithmically utilize this knowledge. A potential gap is the ability to declaratively model this function behavior, like MiniZinc can currently do with global constraints to guide its search.

Therefore the main gaps which can be investigated are, how can we extend the constraint programming software MiniZinc to be able to handle Black Box functions as objective functions and constraints? Then once we have the technology, the question becomes, what methods, hybrid or pure are effective in optimization such problems which are a mix of Black Box and modellable?
#bibliography("bibliography.yml")
