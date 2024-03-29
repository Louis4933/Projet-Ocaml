#use  "Property.ml" ;;
#use "Generator.ml" ;;
#use "Reduction.ml" ;;

module Test :
  sig
    (** Type d'un test portant sur des éléments de type 'a *)
    type 'a t

    (** Construit un test
      * @param gen  générateur pseudo-aléatoire de valeurs de test
      * @param red  stratégie de réduction
      * @param prop propriété qui fait l'objet du test
      * @return     test créé
      *)
    val make_test : 'a Generator.t -> 'a Reduction.t -> 'a Property.t -> 'a t

    (** Effectue un test
      * @param n    nombre de valeurs à tester
      * @param test test à effectuer
      * @return     `true` si n > 0 et que toutes les valeurs à tester satisfont les conditions
      *)
    val check : int -> 'a t -> bool

    (** Cherche une valeur simple ne vérifiant pas la propriété
      * @param n nombre de valeurs à tester
      * @return  `None` si toutes les valeurs de test générées par `gen` vérifient `prop`,
                 une valeur ne vérifiant pas `prop` (éventuellement en appliquant `red`) sinon
      *)
    val fails_at : int -> 'a t -> 'a option

    (** Exécute plusieurs tests
      * @param n     nombre de valeurs testées par test
      * @param tests liste des tests à vérifier
      * @return      tableau associatif des résultats
      *)
    val execute : int -> ('a t) list -> ('a t * 'a option) list
  end =
  struct
    type 'a t = { generator : 'a Generator.t; reduction : 'a Reduction.t; property : 'a Property.t }

    let make_test generatorInput reductionInput propertyInput = 
        { generator = generatorInput; reduction = reductionInput; property = propertyInput }

    let check n test =
        let rec aux i =
          (* si i=n càd si on a fini de vérifier toutes les valeurs on renvoie true *)
          if i = n then true
          else
            (* sinon on génère une nouvelle valeur avec le générateur test.generateur *)
            let x = Generator.next test.generator in
            (* la fonction auxiliaire teste si la propriété est vraie sur la valeur et appelle aux(i+1), sinon elle renvoie false*)
            test.property x && aux (i+1)
        in
        n > 0 && aux 0

    let fails_at n test = 
        let rec aux i =
          (* si toutes les valeurs vérifient la propriété on renvoie None *)
          if i = n then None
          else
            let x = Generator.next test.generator in
            (* si la valeur ne vérifie pas la propriété alors un contre-exemple est renvoyé, 
               sinon on continue à parcourir les valeurs à tester *)
            let x' = test.reduction x in
            if not (test.property x) then Some x else aux (i+1)
            (*if not (test.property x) then Some (List.hd x') else aux (i+1)*)
        in
        aux 0
 
    (* retourne une liste de paires (test, value) où value est soit None si toutes les valeurs à tester vérifient la propriété, 
       soit la première valeur qui ne vérifie pas la propriété *)
    let execute n tests = 
        (* la fonction exécute les tests un par un en appelant la fonction fails_at avec n comme argument pour chaque test de la liste *)
        List.map (fun test -> (test, fails_at n test)) tests

  end ;;
