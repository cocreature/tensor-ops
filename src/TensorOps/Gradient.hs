{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE GADTs               #-}
{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE PolyKinds           #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeOperators       #-}

module TensorOps.Gradient where

-- import           Control.Applicative
-- import           Data.Proxy
-- import           Data.Singletons.Prelude.List ((:++), Reverse, sReverse)
-- import           Data.Type.Combinator
-- import           Data.Type.Equality hiding    (outer)
-- import           Data.Type.Product.Util
-- import           Data.Type.Uniform
-- import           Data.Type.Vector             as TCV
-- import           Data.Type.Vector.Util
-- import           Numeric.AD
-- import           TensorOps.Run
-- import           Type.Class.Higher
-- import           Type.Class.Known
-- import           Type.Family.List
-- import           Type.Family.Nat
-- import           Unsafe.Coerce
import           Data.Type.Length
import           Data.Type.Length.Util           as TCL
import           Data.Type.Product
import           TensorOps.Types
import           Type.Class.Witness
import           Type.Family.List.Util
import qualified TensorOps.Tensor                as Tensor

gradTOp
    :: (Tensor t, Floating (ElemT t))
    => TOp ns ms
    -> Prod t ns    -- ^ inputs
    -> Prod t ms    -- ^ d target / d outputs
    -> Prod t ns    -- ^ d target / d inputs
gradTOp = \case
    Lift uN uM f -> Tensor.gradLift uN uM f
    GMul lM lO lN -> \case
      -- lM   :: Length m
      -- lO   :: Length o
      -- lN   :: Length n
      -- x    :: t (Head ns)
      --      :: t (m :++ o)
      -- y    :: t (Head (Tail ns))
      --      :: t (Reverse o :++ n)
      -- dtdz :: t (Head ms)
      --      :: t (m :++ n)
      x :< y :< Ø -> \case
        dtdz :< Ø -> let rlO = TCL.reverse' lO
      -- gmul :: Length m
      --      -> Length n
      --      -> Length o
      --      -> t (m :++ n)
      --      -> t (Reverse n :++ o)
      --      -> t (m :++ o)
      -- transp y :: t (Reverse (Reverse o :++ n))
      --          :: t (Reverse n :++ Reverse (Reverse o))
      --          :: t (Reverse n :++ o)
      -- therefore we need:
      --   Reverse (Reverse o :++ n) :~: Reverse n :++ Reverse (Reverse o)
      --   Reverse (Reverse o)       :~: o
                     in  gmul lM lN lO dtdz (transp y \\ reverseConcat rlO lN
                                                      \\ reverseReverse lO
                                            )
      -- gmul :: Length (Reverse o)
      --      -> Length (Reverse m)
      --      -> Length n
      --      -> t (Reverse o :++ Reverse m)
      --      -> t (Reverse (Reverse m) :++ n)
      --      -> t (Reverse o :++ n)
      -- transp x :: t (Reverse (m :++ o))
      --          :: t (Reverse o :++ Reverse m)
      -- dtdz     :: t (m :++ o)
      --          :: t (Reverse (Reverse m) :++ o)
      -- therefore we need:
      --   Reverse (m :++ o) :~: Reverse o :++ Reverse m
      --   Reverse (Reverse m) :~: m
                      :< gmul rlO (TCL.reverse' lM) lN
                              (transp x \\ reverseConcat  lM lO)
                              (dtdz     \\ reverseReverse lM   )
                      :< Ø
    Transp lN     -> \case
        _ :< Ø -> \case
          dtdz :< Ø -> only $ transp dtdz \\ reverseReverse lN
    Fold lNs f    -> \case
        x :< Ø -> \case
          -- lNs   :: Length ns
          -- x    :: t (n ': ns)
          -- dtdz :: t ns
          -- goal :: t (n ': ns)
          -- nope!
          -- gmul :: Length '[n]
          --      -> Length '[]
          --      -> Length ns
          --      -> t '[n]         -- ??
          --      -> t ns
          --      -> t (n ': ns)
          dtdz :< Ø -> only $ gmul (LS LZ) LZ lNs (undefined x) dtdz

