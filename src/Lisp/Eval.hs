module Lisp.Eval where

import Lisp.Ast

import Control.Monad (liftM, ap)



-- monad
type Lookup a = [(String, a)]

type Fun = SExpr -> Eval SExpr

data State = State
  { sPendingOutput :: [String]
  , sPendingInput :: [String]
  , sVars :: Lookup SExpr
  , sFuns :: Lookup Fun
  }

instance Show State where
  show s = "State {sVars = " ++ show (sVars s) ++ "}"

data LispError = LispError String deriving Show

newtype Eval a = Eval (State -> (State, Either (Either a LispError) (Eval a)))

instance Functor Eval where
  fmap = liftM

instance Applicative Eval where
  pure  = return
  (<*>) = ap

instance Monad Eval where
  Eval c1 >>= fc2 = Eval (\s -> case c1 s of
    (s', Left (Right e)) -> (s', Left (Right e))
    (s', Left (Left v)) -> let Eval c2 = fc2 v in c2 s'
    (s', Right pc1) -> (s', Right (pc1 >>= fc2)))

  return v = Eval (\s -> (s, Left (Left v)))



--
initState :: State
initState = State [] [] [] []

eval :: SExpr -> Eval SExpr
eval = return

evalIO :: State -> Eval SExpr -> IO (State, Either SExpr LispError)
evalIO s (Eval c) = let (s', Left r) = c s in return (s', r)

-- TODO: runtime error
todo_runtime_error :: a
todo_runtime_error = error "TODO"



-- _lisp_*

_lisp_bool :: Bool -> SExpr
_lisp_bool True = _lisp_true
_lisp_bool False = _lisp_false

_lisp_false :: SExpr
_lisp_false = EmptyList

_lisp_true :: SExpr
_lisp_true = lisp_T



-- lisp_*

lisp_T :: SExpr
lisp_T = Atom "T"

lisp_atomp :: SExpr -> SExpr
lisp_atomp (DottedPair _ _) = _lisp_false
lisp_atomp _ = _lisp_true

lisp_numberp :: SExpr -> SExpr
lisp_numberp (IntegerLiteral _) = _lisp_true
lisp_numberp (FloatLiteral _) = _lisp_true
lisp_numberp _ = _lisp_false

lisp_listp :: SExpr -> SExpr
lisp_listp EmptyList = _lisp_true
lisp_listp (DottedPair _ _) = _lisp_true
lisp_listp _ = _lisp_false

lisp__eq :: SExpr -> SExpr -> SExpr
lisp__eq (IntegerLiteral x) (IntegerLiteral y) = _lisp_bool (x == y)
lisp__eq (FloatLiteral x) (FloatLiteral y) = _lisp_bool (x == y)
lisp__eq (IntegerLiteral x) (FloatLiteral y) = _lisp_bool (fromIntegral x == y)
lisp__eq (FloatLiteral x) (IntegerLiteral y) = _lisp_bool (x == fromIntegral y)
lisp__eq _ _ = todo_runtime_error

lisp_cons :: SExpr -> SExpr -> SExpr
lisp_cons car cdr = DottedPair car cdr

lisp_car :: SExpr -> SExpr
lisp_car (DottedPair car _) = car
lisp_car _ = todo_runtime_error

lisp_cdr :: SExpr -> SExpr
lisp_cdr (DottedPair _ cdr) = cdr
lisp_cdr _ = todo_runtime_error
