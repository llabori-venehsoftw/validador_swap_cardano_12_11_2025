// ============================================
// lib/validations/swap.ak
// Validaciones específicas de swaps
// ============================================

use aiken/transaction.{Input, Output, ScriptContext, Spend, Transaction}
use aiken/transaction/value.{lovelace_of, quantity_of}
use swap_inicial/lib/types.{PoolDatum}
use swap_inicial/lib/math/amm.{
  calculate_ada_output, calculate_token_output, verify_constant_product,
}
use swap_inicial/lib/helpers/pool.{
  get_pool_ada_amount, get_pool_token_amount, get_pool_input,
}

// ============================================
// VALIDACIONES DE SWAP ADA → TOKEN
// ============================================

/// Valida que el swap de ADA por tokens sea correcto
/// 
/// # Argumentos
/// * `datum` - Datum del pool antes del swap
/// * `new_datum` - Datum del pool después del swap
/// * `pool_input` - Input del pool
/// * `pool_output` - Output del pool
/// * `min_token_out` - Mínimo de tokens a recibir (slippage protection)
/// 
/// # Retorna
/// * True si el swap es válido
pub fn validate_swap_ada_for_token_amounts(
  datum: PoolDatum,
  new_datum: PoolDatum,
  pool_input: Input,
  pool_output: Output,
  min_token_out: Int,
) -> Bool {
  
  // 1. Calcular cuánto ADA entró
  let old_ada = lovelace_of(pool_input.output.value)
  let new_ada = lovelace_of(pool_output.value)
  let ada_in = new_ada - old_ada
  
  // 2. Calcular cuántos tokens salieron
  let old_tokens = quantity_of(
    pool_input.output.value,
    datum.token_policy,
    datum.token_name,
  )
  let new_tokens = quantity_of(
    pool_output.value,
    datum.token_policy,
    datum.token_name,
  )
  let tokens_out = old_tokens - new_tokens
  
  // 3. Validar cantidades positivas
  let valid_amounts =
    and {
      ada_in > 0,
      tokens_out > 0,
    }
  
  // 4. Calcular output esperado
  let expected_tokens_out = calculate_token_output(
    datum.token_reserve,
    datum.ada_reserve,
    ada_in,
    datum.fee_bps,
  )
  
  // 5. Validar slippage protection
  let slippage_ok = tokens_out >= min_token_out
  
  // 6. Validar cantidad correcta (con pequeña tolerancia)
  let amount_correct = tokens_out >= expected_tokens_out
  
  // 7. Validar actualización de reservas
  let reserves_correct =
    and {
      new_datum.ada_reserve == datum.ada_reserve + ada_in,
      new_datum.token_reserve == datum.token_reserve - tokens_out,
    }
  
  // 8. Verificar producto constante
  let k_maintained = verify_constant_product(
    datum.ada_reserve,
    datum.token_reserve,
    new_datum.ada_reserve,
    new_datum.token_reserve,
    datum.fee_bps,
  )
  
  and {
    valid_amounts,
    slippage_ok,
    amount_correct,
    reserves_correct,
    k_maintained,
  }
}

// ============================================
// VALIDACIONES DE SWAP TOKEN → ADA
// ============================================

/// Valida que el swap de tokens por ADA sea correcto
/// 
/// # Argumentos
/// * `datum` - Datum del pool antes del swap
/// * `new_datum` - Datum del pool después del swap
/// * `pool_input` - Input del pool
/// * `pool_output` - Output del pool
/// * `min_ada_out` - Mínimo de ADA a recibir (slippage protection)
/// 
/// # Retorna
/// * True si el swap es válido
pub fn validate_swap_token_for_ada_amounts(
  datum: PoolDatum,
  new_datum: PoolDatum,
  pool_input: Input,
  pool_output: Output,
  min_ada_out: Int,
) -> Bool {
  
  // 1. Calcular cuántos tokens entraron
  let old_tokens = quantity_of(
    pool_input.output.value,
    datum.token_policy,
    datum.token_name,
  )
  let new_tokens = quantity_of(
    pool_output.value,
    datum.token_policy,
    datum.token_name,
  )
  let tokens_in = new_tokens - old_tokens
  
  // 2. Calcular cuánto ADA salió
  let old_ada = lovelace_of(pool_input.output.value)
  let new_ada = lovelace_of(pool_output.value)
  let ada_out = old_ada - new_ada
  
  // 3. Validar cantidades positivas
  let valid_amounts =
    and {
      tokens_in > 0,
      ada_out > 0,
    }
  
  // 4. Calcular output esperado
  let expected_ada_out = calculate_ada_output(
    datum.ada_reserve,
    datum.token_reserve,
    tokens_in,
    datum.fee_bps,
  )
  
  // 5. Validar slippage protection
  let slippage_ok = ada_out >= min_ada_out
  
  // 6. Validar cantidad correcta
  let amount_correct = ada_out >= expected_ada_out
  
  // 7. Validar actualización de reservas
  let reserves_correct =
    and {
      new_datum.token_reserve == datum.token_reserve + tokens_in,
      new_datum.ada_reserve == datum.ada_reserve - ada_out,
    }
  
  // 8. Verificar producto constante
  let k_maintained = verify_constant_product(
    datum.ada_reserve,
    datum.token_reserve,
    new_datum.ada_reserve,
    new_datum.token_reserve,
    datum.fee_bps,
  )
  
  and {
    valid_amounts,
    slippage_ok,
    amount_correct,
    reserves_correct,
    k_maintained,
  }
}

// ============================================
// VALIDACIONES GENERALES DE SWAP
// ============================================

/// Verifica que el precio del swap esté dentro de límites razonables
/// Previene ataques de manipulación de precio
/// 
/// # Argumentos
/// * `amount_in` - Cantidad de entrada
/// * `reserve_in` - Reserva del asset de entrada
/// * `max_impact_bps` - Máximo impacto permitido (ej: 2000 = 20%)
/// 
/// # Retorna
/// * True si el impacto está dentro del límite
pub fn validate_price_impact(
  amount_in: Int,
  reserve_in: Int,
  max_impact_bps: Int,
) -> Bool {
  // Calcular impacto: (amount_in / reserve_in) * 10000
  let impact_bps = ( amount_in * 10000 ) / reserve_in
  
  impact_bps <= max_impact_bps
}

/// Verifica que el swap no vacíe excesivamente el pool
/// 
/// # Argumentos
/// * `new_reserve` - Nueva reserva después del swap
/// * `min_reserve` - Mínimo de reserva a mantener
/// 
/// # Retorna
/// * True si la reserva es suficiente
pub fn validate_minimum_reserve(new_reserve: Int, min_reserve: Int) -> Bool {
  new_reserve >= min_reserve
}