with Alire.Dependencies;
with Alire.Index;
with Alire.Properties;
with Alire.Solutions;
with Alire.TOML_Adapters;
with Alire.Types;

with Semantic_Versioning.Extended;

with TOML;

package Alire.Solver is

   --------------
   -- Policies --
   --------------

   type Age_Policies is (Oldest, Newest);
   --  When looking for releases within a crate, which one to try first.

   type Completeness_Policies is
     (First_Complete,
      --  Stop after finding the first complete solution. No incomplete
      --  solutions will be attempted. Other complete solutions may exist
      --  that are globally "newer".

      All_Complete,
      --  Only attempt to find complete solutions; the first unsatisfiable
      --  dependency will result in abandoning that search branch. All
      --  complete solutions will be found, and the best one according
      --  to Solutions.Is_Better will be returned.

      Some_Incomplete,
      --  Explores a reasonable subset of incomplete solutions: unknown crates,
      --  crates with no satisfying releases, crates with externals can appear
      --  as missing in the solution.

      All_Incomplete
      --  All crates may appear as missing, even those that have satisfying
      --  releases. All possible solutions and incomplete subsets are
      --  eventually explored.

     );
   --  Allow the solver to further explore incomplete solution space. Each
   --  value takes more time than the precedent one. All_Incomplete can take
   --  a veeery long time when many crates/releases must be considered.

   type Detection_Policies is (Detect, Dont_Detect);
   --  * Detect: externals will be detected and added to the index once needed.
   --  * Dont_Detect: externals will remain undetected (faster).

   type Hinting_Policies is (Hint, Fail);
   --  * Hint: any crate with externals, detected or not, will as last resort
   --  provide a hint.
   --  * Fail: fail for any unsatisfiable crate. If Detect, externally detected
   --  releases will be used normally; otherwise a crate with only externals
   --  will always cause failure.

   subtype Release  is Types.Release;

   subtype Solution is Solutions.Solution;

   --  The dependency solver (Resolve subprogram, below) receives a
   --  dependency tree and will return the best solution found (exploration
   --  is exhaustive), according to Solutions.Is_Better ordering. System
   --  dependencies are resolved in platforms with system packager support.
   --  Otherwise they're filed as "hints". In this case, a warning will
   --  be provided for the user with a list of the dependencies that are
   --  externally required. Note that a solution is always returned, but
   --  it might not be complete.

   ---------------------
   --  Basic queries  --
   --  Merely check the catalog

   function Exists (Name    : Alire.Crate_Name;
                    Version : Semantic_Versioning.Version)
                    return Boolean renames Alire.Index.Exists;

   function Find (Name    : Alire.Crate_Name;
                  Version : Semantic_Versioning.Version)
                  return Release
   renames Alire.Index.Find;

   function Exists
     (Name    : Alire.Crate_Name;
      Allowed : Semantic_Versioning.Extended.Version_Set :=
        Semantic_Versioning.Extended.Any)
      return Boolean;

   function Find
     (Name    : Alire.Crate_Name;
      Allowed : Semantic_Versioning.Extended.Version_Set :=
        Semantic_Versioning.Extended.Any;
      Policy  : Age_Policies)
      return Release
     with Pre =>
       Exists (Name, Allowed) or else
       raise Query_Unsuccessful
         with "Release within requested version not found: "
              & Dependencies.New_Dependency (Name, Allowed).Image;

   -----------------------
   --  Advanced queries --
   --  They may need to travel the full catalog, with multiple individual
   --  availability checks.

   type Query_Options is record
      Age          : Age_Policies          := Newest;
      Completeness : Completeness_Policies := First_Complete;
      Detecting    : Detection_Policies    := Detect;
      Hinting      : Hinting_Policies      := Hint;
   end record;

   Default_Options : constant Query_Options := (others => <>);
   --  A reasonable combo that will return the first complete solution found,
   --  or otherwise consider a subset of incomplete solutions.

   Exhaustive_Options : constant Query_Options :=
                          (Completeness => All_Incomplete,
                           others       => <>);
   --  Explore the full solution space

   Find_Best_Options  : constant Query_Options :=
                          (Completeness => All_Complete,
                           others       => <>);
   --  Find all complete solutions and return the "best" one (see
   --  Solutions.Is_Better). It does not yet make sense to use this setting
   --  because with the current Is_Better implementation, the first complete
   --  solution found is the one considered better anyway.

   function Resolve (Deps    : Alire.Types.Abstract_Dependencies;
                     Props   : Properties.Vector;
                     Current : Solution;
                     Options : Query_Options := Default_Options)
                     return Solution;
   --  Exhaustively look for a solution to the given dependencies, under the
   --  given platform properties and lookup options. A current solution may
   --  be given and pinned releases will be reused.

   function Is_Resolvable (Deps    : Types.Abstract_Dependencies;
                           Props   : Properties.Vector;
                           Current : Solution;
                           Options : Query_Options := Default_Options)
                           return Boolean;
   --  Simplified call to Resolve, discarding result

end Alire.Solver;
