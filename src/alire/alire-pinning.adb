with Alire.Solver;

package body Alire.Pinning is

   use type Conditional.Dependencies;

   ---------
   -- Pin --
   ---------

   function Pin (Crate        : Crate_Name;
                 Version      : Semantic_Versioning.Version;
                 Dependencies : Conditional.Dependencies;
                 Environment  : Properties.Vector;
                 Solution     : Solutions.Solution)
                 return Solutions.Solution
   is
      --  We solve forcing the new version, while preemptively removing any
      --  previous pin for the same crate, since two pins to different versions
      --  would be unsolvable. A link is also preemptively removed to prevent
      --  simultaneous pinning and linking.
   begin
      return
        Solver.Resolve
          (Conditional.New_Dependency (Crate, Version) and Dependencies,
           Environment,
           Solution.Unpinning (Crate).Missing (Crate))
            .Pinning (Crate, Version);
   end Pin;

   ------------
   -- Pin_To --
   ------------

   function Pin_To (Crate        : Crate_Name;
                    URL          : String;
                    Dependencies : Conditional.Dependencies;
                    Environment  : Properties.Vector;
                    Solution     : Solutions.Solution)
                    return Solutions.Solution
   --  Just in case it was already pinned to a version, we remove that hidden
   --  restriction, and re-solve so any old constraints in the dependencies
   --  caused by the old pin disappear.
   is (Solver.Resolve
       (Dependencies,
        Environment,
        Solution
        .Unpinning (Crate)
        .Linking (Crate, URL)));

   -----------
   -- Unpin --
   -----------

   function Unpin (Crate        : Crate_Name;
                   Dependencies : Conditional.Dependencies;
                   Environment  : Properties.Vector;
                   Solution     : Solutions.Solution)
                   return Solutions.Solution
   is
   begin
      --  The unpin case is simpler since we need only to remove any previous
      --  pin for the crate, and let the solver operate normally. Likewise for
      --  a linked dependency.

      return Solver.Resolve
        (Dependencies,
         Environment,
         Solution
         .Missing (Crate)     -- Clears any previous link
         .Unpinning (Crate)); -- Clears any previous pin
   end Unpin;

end Alire.Pinning;
