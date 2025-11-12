// ============================================
// lib/validations/datum.ak
// Validaciones del datum del pool
// ============================================

use swap_inicial/lib/types.{PoolDatum}
use swap_inicial/lib/constants.{
  max_fee_bps, min_ada_reserve, min_fee_bps, min_token_reserve,
}

// ============================================
// VALIDACIONES DE INMUTABILIDAD
// ============================================

/// Verifica que el datum no cambie excepto las reservas
/// 
/// # Argumentos
/// * `old` - Datum anterior
/// * `new` - Datum nuevo
/// 
/// # Retorna
/// * True si solo cambiaron las reservas
pub fn verify_datum_unchanged_except_reserves(
  old: PoolDatum,
  new: PoolDatum,
) -> Bool {
  and {
    old.token_policy == new.token_policy,
    old.token_name == new.token_name,
    old.fee_bps == new.fee_bps,
    old.pool_owner == new.pool_owner,
    old.total_shares == new.total_shares,
  }
}

/// Verifica que el datum no cambie excepto reservas y shares
/// 
/// # Argumentos
/// * `old` - Datum anterior
/// * `new` - Datum nuevo
/// 
/// # Retorna
/// * True si solo cambiaron reservas y shares
pub fn verify_datum_unchanged_except_reserves_and_shares(
  old: PoolDatum,
  new: PoolDatum,
) -> Bool {
  and {
    old.token_policy == new.token_policy,
    old.token_name == new.token_name,
    old.fee_bps == new.fee_bps,
    old.pool_owner == new.pool_owner,
  }
}

/// Verifica que el datum sea completamente idéntico
/// 
/// # Argumentos
/// * `datum1` - Primer datum
/// * `datum2` - Segundo datum
/// 
/// # Retorna
/// * True si son idénticos
pub fn verify_datum_identical(datum1: PoolDatum, datum2: PoolDatum) -> Bool {
  and {
    datum1.token_policy == datum2.token_policy,
    datum1.token_name == datum2.token_name,
    datum1.token_reserve == datum2.token_reserve,
    datum1.ada_reserve == datum2.ada_reserve,
    datum1.fee_bps == datum2.fee_bps,
    datum1.pool_owner == datum2.pool_owner,
    datum1.total_shares == datum2.total_shares,
  }
}

// ============================================
// VALIDACIONES DE DATOS
// ============================================

/// Valida que los datos del pool sean correctos
/// 
/// # Argumentos
/// * `datum` - Datum del pool a validar
/// 
/// # Retorna
/// * True si el datum es válido
pub fn validate_pool_datum(datum: PoolDatum) -> Bool {
  and {
    // 1. Reservas deben ser positivas
    datum.ada_reserve >= min_ada_reserve,
    datum.token_reserve >= min_token_reserve,
    // 2. Fee debe estar en rango válido
    datum.fee_bps >= min_fee_bps,
    datum.fee_bps <= max_fee_bps,
    // 3. Shares no pueden ser negativos
    datum.total_shares >= 0,
    // 4. Token policy y name no vacíos
    !is_empty_policy(datum.token_policy),
    !is_empty_asset_name(datum.token_name),
  }
}

/// Verifica que un policy ID no esté vacío
fn is_empty_policy(policy: ByteArray) -> Bool {
  policy == #""
}

/// Verifica que un asset name no esté vacío
fn is_empty_asset_name(name: ByteArray) -> Bool {
  name == #""
}

// ============================================
// VALIDACIONES DE RESERVAS
// ============================================

/// Valida que las reservas hayan cambiado de forma válida
/// 
/// # Argumentos
/// * `old_ada` - Reserva ADA anterior
/// * `old_tokens` - Reserva tokens anterior
/// * `new_ada` - Nueva reserva ADA
/// * `new_tokens` - Nueva reserva tokens
/// 
/// # Retorna
/// * True si el cambio es válido
pub fn validate_reserve_change(
  old_ada: Int,
  old_tokens: Int,
  new_ada: Int,
  new_tokens: Int,
) -> Bool {
  // Al menos una reserva debe haber cambiado
  let something_changed =
    or {
      old_ada != new_ada,
      old_tokens != new_tokens,
    }
  
  // Ambas reservas deben mantenerse positivas
  let both_positive =
    and {
      new_ada > 0,
      new_tokens > 0,
    }
  
  and {
    something_changed,
    both_positive,
  }
}

/// Valida que los shares hayan cambiado de forma válida
/// 
/// # Argumentos
/// * `old_shares` - Shares anteriores
/// * `new_shares` - Nuevos shares
/// * `delta` - Cambio esperado (puede ser negativo)
/// 
/// # Retorna
/// * True si el cambio es correcto
pub fn validate_shares_change(
  old_shares: Int,
  new_shares: Int,
  delta: Int,
) -> Bool {
  and {
    new_shares == old_shares + delta,
    new_shares >= 0,
  }
}

// ============================================
// TESTS
// ============================================

test validate_pool_datum_valid() {
  let valid_datum =
    PoolDatum {
      token_policy: #"abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd12",
      token_name: #"544f4b454e",
      token_reserve: 10000000000,
      ada_reserve: 1000000000,
      fee_bps: 30,
      pool_owner: #"aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbcc",
      total_shares: 1000000000,
    }
  
  validate_pool_datum(valid_datum)
}

test validate_pool_datum_invalid_fee() {
  let invalid_datum =
    PoolDatum {
      token_policy: #"abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd12",
      token_name: #"544f4b454e",
      token_reserve: 10000000000,
      ada_reserve: 1000000000,
      fee_bps: 2000, // > max_fee_bps (1000)
      pool_owner: #"aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbcc",
      total_shares: 1000000000,
    }
  
  !validate_pool_datum(invalid_datum)
}