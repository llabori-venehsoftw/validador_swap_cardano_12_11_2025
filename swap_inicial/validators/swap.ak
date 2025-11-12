// ============================================
// validators/swap.ak
// Validador principal (orquestador)
// ============================================

use aiken/list
use aiken/transaction.{ScriptContext, Spend, Transaction}
use swap_inicial/lib/types.{PoolDatum, SwapRedeemer}
use swap_inicial/lib/helpers/pool.{
  find_pool_continuation_output, get_pool_datum_from_output, get_pool_input,
  has_pool_continuation_output,
}
use swap_init/lib/validations/datum.{
  verify_datum_unchanged_except_reserves,
  verify_datum_unchanged_except_reserves_and_shares,
}
use swap_init/lib/validations/swap.{
  validate_swap_ada_for_token_amounts, validate_swap_token_for_ada_amounts,
}

// Importar validaciones de liquidez (a implementar similar a swap)
// use swap_init/lib/validations/liquidity.{
//   validate_add_liquidity_amounts,
//   validate_remove_liquidity_amounts,
// }

// ============================================
// SPENDING VALIDATOR
// ============================================

validator swap_pool {
  spend(
    datum: Option<PoolDatum>,
    redeemer: SwapRedeemer,
    _input: OutputReference,
    ctx: ScriptContext,
  ) {
    expect Some(pool_datum) = datum
    
    let tx = ctx.transaction
    let tx = ctx.transaction
    
    when redeemer is {
      SwapAdaForToken { min_token_out } ->
        validate_swap_ada_for_token(datum, tx, ctx, min_token_out)
      
      SwapTokenForAda { min_ada_out } ->
        validate_swap_token_for_ada(datum, tx, ctx, min_ada_out)
      
      AddLiquidity { ada_amount, token_amount } ->
        validate_add_liquidity(datum, tx, ctx, ada_amount, token_amount)
      
      RemoveLiquidity { shares_amount } ->
        validate_remove_liquidity(datum, tx, ctx, shares_amount)
      
      ClosePool -> validate_close_pool(datum, tx, ctx)
    }
  }
}

// ============================================
// SWAP: ADA → TOKEN (usando módulos)
// ============================================

fn validate_swap_ada_for_token(
  datum: PoolDatum,
  tx: Transaction,
  ctx: ScriptContext,
  min_token_out: Int,
) -> Bool {
  
  // 1. Obtener inputs y outputs del pool
  let pool_input = get_pool_input(ctx)
  
  expect Some(pool_output) = find_pool_continuation_output(tx.outputs, ctx)
  
  // 2. Obtener nuevo datum
  let new_datum = get_pool_datum_from_output(pool_output)
  
  // 3. ⭐ Usar función modular para validar cantidades
  let amounts_valid = validate_swap_ada_for_token_amounts(
    datum,
    new_datum,
    pool_input,
    pool_output,
    min_token_out,
  )
  
  // 4. ⭐ Usar función modular para validar datum
  let datum_unchanged = verify_datum_unchanged_except_reserves(datum, new_datum)
  
  and {
    amounts_valid,
    datum_unchanged,
  }
}

// ============================================
// SWAP: TOKEN → ADA (usando módulos)
// ============================================

fn validate_swap_token_for_ada(
  datum: PoolDatum,
  tx: Transaction,
  ctx: ScriptContext,
  min_ada_out: Int,
) -> Bool {
  
  let pool_input = get_pool_input(ctx)
  expect Some(pool_output) = find_pool_continuation_output(tx.outputs, ctx)
  let new_datum = get_pool_datum_from_output(pool_output)
  
  // ⭐ Usar funciones modulares
  let amounts_valid = validate_swap_token_for_ada_amounts(
    datum,
    new_datum,
    pool_input,
    pool_output,
    min_ada_out,
  )
  
  let datum_unchanged = verify_datum_unchanged_except_reserves(datum, new_datum)
  
  and {
    amounts_valid,
    datum_unchanged,
  }
}

// ============================================
// ADD LIQUIDITY (simplificado - usar módulos)
// ============================================

fn validate_add_liquidity(
  datum: PoolDatum,
  tx: Transaction,
  ctx: ScriptContext,
  ada_amount: Int,
  token_amount: Int,
) -> Bool {
  
  let pool_input = get_pool_input(ctx)
  expect Some(pool_output) = find_pool_continuation_output(tx.outputs, ctx)
  let new_datum = get_pool_datum_from_output(pool_output)
  
  // Aquí usarías validate_add_liquidity_amounts del módulo
  // Por ahora, validación básica
  let datum_ok = verify_datum_unchanged_except_reserves_and_shares(
    datum,
    new_datum,
  )
  
  and {
    ada_amount > 0,
    token_amount > 0,
    datum_ok,
  }
}

// ============================================
// REMOVE LIQUIDITY (simplificado)
// ============================================

fn validate_remove_liquidity(
  datum: PoolDatum,
  tx: Transaction,
  ctx: ScriptContext,
  shares_amount: Int,
) -> Bool {
  
  let pool_input = get_pool_input(ctx)
  expect Some(pool_output) = find_pool_continuation_output(tx.outputs, ctx)
  let new_datum = get_pool_datum_from_output(pool_output)
  
  let datum_ok = verify_datum_unchanged_except_reserves_and_shares(
    datum,
    new_datum,
  )
  
  and {
    shares_amount > 0,
    datum_ok,
  }
}

// ============================================
// CLOSE POOL
// ============================================

fn validate_close_pool(
  datum: PoolDatum,
  tx: Transaction,
  ctx: ScriptContext,
) -> Bool {
  
  // Solo el propietario puede cerrar
  let signed_by_owner = list.has(tx.extra_signatories, datum.pool_owner)
  
  // No debe haber continuación
  let no_continuation = !has_pool_continuation_output(tx.outputs, ctx)
  
  and {
    signed_by_owner,
    no_continuation,
  }
}