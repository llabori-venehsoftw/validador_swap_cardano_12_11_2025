// ============================================
// lib/helpers/pool.ak
// Funciones auxiliares para operaciones del pool
// ============================================

use aiken/list
use aiken/transaction.{InlineDatum, Input, Output, ScriptContext, Spend}
use aiken/transaction/value.{lovelace_of, quantity_of}
use swap_inicial/lib/types.{PoolDatum}

// ============================================
// BÚSQUEDA DE UTXOS
// ============================================

/// Obtiene el input del pool que se está gastando
/// 
/// # Argumentos
/// * `ctx` - Contexto del script
/// 
/// # Retorna
/// * Input del pool
pub fn get_pool_input(ctx: ScriptContext) -> Input {
  expect Spend(output_reference) = ctx.purpose
  
  expect Some(pool_input) =
    list.find(
      ctx.transaction.inputs,
      fn(input) { input.output_reference == output_reference },
    )
  
  pool_input
}

/// Encuentra el output de continuación del pool
/// 
/// # Argumentos
/// * `outputs` - Lista de outputs
/// * `ctx` - Contexto del script
/// 
/// # Retorna
/// * Some(output) si existe, None si no
pub fn find_pool_continuation_output(
  outputs: List<Output>,
  ctx: ScriptContext,
) -> Option<Output> {
  let pool_input = get_pool_input(ctx)
  let script_address = pool_input.output.address
  
  list.find(outputs, fn(output) { output.address == script_address })
}

/// Verifica si existe un output de continuación
/// 
/// # Argumentos
/// * `outputs` - Lista de outputs
/// * `ctx` - Contexto del script
/// 
/// # Retorna
/// * True si existe continuación
pub fn has_pool_continuation_output(
  outputs: List<Output>,
  ctx: ScriptContext,
) -> Bool {
  when find_pool_continuation_output(outputs, ctx) is {
    Some(_) -> True
    None -> False
  }
}

// ============================================
// EXTRACCIÓN DE DATOS
// ============================================

/// Obtiene el datum del pool desde un output
/// 
/// # Argumentos
/// * `output` - Output que contiene el datum
/// 
/// # Retorna
/// * PoolDatum
pub fn get_pool_datum_from_output(output: Output) -> PoolDatum {
  expect InlineDatum(datum_data) = output.datum
  expect datum: PoolDatum = datum_data
  datum
}

/// Obtiene la cantidad de ADA en un output del pool
/// 
/// # Argumentos
/// * `output` - Output del pool
/// 
/// # Retorna
/// * Cantidad de lovelace
pub fn get_pool_ada_amount(output: Output) -> Int {
  lovelace_of(output.value)
}

/// Obtiene la cantidad de tokens en un output del pool
/// 
/// # Argumentos
/// * `output` - Output del pool
/// * `datum` - Datum del pool (para obtener policy y name)
/// 
/// # Retorna
/// * Cantidad de tokens
pub fn get_pool_token_amount(output: Output, datum: PoolDatum) -> Int {
  quantity_of(output.value, datum.token_policy, datum.token_name)
}

// ============================================
// VERIFICACIONES DE ESTRUCTURA
// ============================================

/// Verifica que un output tenga la estructura correcta de pool
/// 
/// # Argumentos
/// * `output` - Output a verificar
/// * `expected_address` - Dirección esperada del script
/// 
/// # Retorna
/// * True si tiene la estructura correcta
pub fn verify_pool_output_structure(
  output: Output,
  expected_address: Address,
) -> Bool {
  and {
    // Dirección correcta
    output.address == expected_address,
    // Tiene datum inline
    has_inline_datum(output),
  }
}

/// Verifica que un output tenga datum inline
fn has_inline_datum(output: Output) -> Bool {
  when output.datum is {
    InlineDatum(_) -> True
    _ -> False
  }
}

// ============================================
// CÁLCULOS DE CAMBIOS
// ============================================

/// Calcula el cambio en reservas entre dos estados del pool
/// 
/// # Argumentos
/// * `old_datum` - Datum anterior
/// * `new_datum` - Datum nuevo
/// 
/// # Retorna
/// * (delta_ada, delta_tokens, delta_shares)
pub fn calculate_pool_deltas(
  old_datum: PoolDatum,
  new_datum: PoolDatum,
) -> (Int, Int, Int) {
  let ada_delta = new_datum.ada_reserve - old_datum.ada_reserve
  let token_delta = new_datum.token_reserve - old_datum.token_reserve
  let shares_delta = new_datum.total_shares - old_datum.total_shares
  
  (ada_delta, token_delta, shares_delta)
}

/// Verifica que los cambios sean consistentes con una operación específica
/// 
/// # Argumentos
/// * `ada_delta` - Cambio en ADA
/// * `token_delta` - Cambio en tokens
/// * `shares_delta` - Cambio en shares
/// * `expected_operation` - "swap_ada_in", "swap_token_in", "add_liq", "remove_liq"
/// 
/// # Retorna
/// * True si los deltas son consistentes
pub fn verify_deltas_consistent_with_operation(
  ada_delta: Int,
  token_delta: Int,
  shares_delta: Int,
  operation_type: ByteArray,
) -> Bool {
  when operation_type is {
    // Swap ADA → Token: ADA aumenta, Tokens disminuyen, Shares sin cambio
    #"737761705f6164615f696e" ->
      and {
        ada_delta > 0,
        token_delta < 0,
        shares_delta == 0,
      }
    // Swap Token → ADA: Tokens aumentan, ADA disminuye, Shares sin cambio
    #"737761705f746f6b656e5f696e" ->
      and {
        token_delta > 0,
        ada_delta < 0,
        shares_delta == 0,
      }
    // Add Liquidity: ADA aumenta, Tokens aumentan, Shares aumentan
    #"6164645f6c6971" ->
      and {
        ada_delta > 0,
        token_delta > 0,
        shares_delta > 0,
      }
    // Remove Liquidity: ADA disminuye, Tokens disminuyen, Shares disminuyen
    #"72656d6f76655f6c6971" ->
      and {
        ada_delta < 0,
        token_delta < 0,
        shares_delta < 0,
      }
    _ -> False
  }
}

// ============================================
// UTILIDADES DE COMPARACIÓN
// ============================================

/// Compara dos outputs del pool para ver si el value cambió
/// 
/// # Argumentos
/// * `old_output` - Output anterior
/// * `new_output` - Output nuevo
/// 
/// # Retorna
/// * True si el value cambió
pub fn pool_value_changed(old_output: Output, new_output: Output) -> Bool {
  old_output.value != new_output.value
}

/// Verifica que el datum haya sido actualizado correctamente
/// 
/// # Argumentos
/// * `old_output` - Output anterior
/// * `new_output` - Output nuevo
/// 
/// # Retorna
/// * (old_datum, new_datum)
pub fn get_datum_pair(
  old_output: Output,
  new_output: Output,
) -> (PoolDatum, PoolDatum) {
  let old_datum = get_pool_datum_from_output(old_output)
  let new_datum = get_pool_datum_from_output(new_output)
  
  (old_datum, new_datum)
}