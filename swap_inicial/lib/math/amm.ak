// ============================================
// lib/math/amm.ak
// Fórmulas del Automated Market Maker
// ============================================

use swap_inicial/lib/constants.{basis_points_base}

// ============================================
// CÁLCULOS DE SWAP
// ============================================

/// Calcula la cantidad de tokens a recibir por ADA
/// Formula: token_out = (token_reserve * ada_in * (10000 - fee)) / 
///                      ((ada_reserve * 10000) + (ada_in * (10000 - fee)))
/// 
/// # Argumentos
/// * `token_reserve` - Cantidad de tokens en el pool
/// * `ada_reserve` - Cantidad de ADA en el pool
/// * `ada_in` - Cantidad de ADA que entra
/// * `fee_bps` - Fee en basis points
/// 
/// # Retorna
/// * Cantidad de tokens a recibir
pub fn calculate_token_output(
  token_reserve: Int,
  ada_reserve: Int,
  ada_in: Int,
  fee_bps: Int,
) -> Int {
  // Aplicar fee al input
  let ada_in_with_fee = ada_in * (basis_points_base - fee_bps)
  
  // Numerador: token_reserve * ada_in_with_fee
  let numerator = token_reserve * ada_in_with_fee
  
  // Denominador: (ada_reserve * 10000) + ada_in_with_fee
  let denominator = ( ada_reserve * basis_points_base ) + ada_in_with_fee
  
  // Resultado: numerator / denominator
  numerator / denominator
}

/// Calcula la cantidad de ADA a recibir por tokens
/// Formula: ada_out = (ada_reserve * token_in * (10000 - fee)) / 
///                    ((token_reserve * 10000) + (token_in * (10000 - fee)))
/// 
/// # Argumentos
/// * `ada_reserve` - Cantidad de ADA en el pool
/// * `token_reserve` - Cantidad de tokens en el pool
/// * `token_in` - Cantidad de tokens que entra
/// * `fee_bps` - Fee en basis points
/// 
/// # Retorna
/// * Cantidad de ADA a recibir
pub fn calculate_ada_output(
  ada_reserve: Int,
  token_reserve: Int,
  token_in: Int,
  fee_bps: Int,
) -> Int {
  // Aplicar fee al input
  let token_in_with_fee = token_in * (basis_points_base - fee_bps)
  
  // Numerador: ada_reserve * token_in_with_fee
  let numerator = ada_reserve * token_in_with_fee
  
  // Denominador: (token_reserve * 10000) + token_in_with_fee
  let denominator = ( token_reserve * basis_points_base ) + token_in_with_fee
  
  // Resultado
  numerator / denominator
}

// ============================================
// CÁLCULOS DE LIQUIDEZ
// ============================================

/// Calcula shares a emitir al agregar liquidez
/// Formula: shares = (deposited_ada / ada_reserve) * total_shares
/// 
/// Para la primera liquidez: shares = deposited_ada
/// 
/// # Argumentos
/// * `total_shares` - Total de shares existentes
/// * `ada_reserve` - Reserva de ADA actual
/// * `deposited_ada` - ADA a depositar
/// 
/// # Retorna
/// * Cantidad de shares a emitir
pub fn calculate_shares(
  total_shares: Int,
  ada_reserve: Int,
  deposited_ada: Int,
) -> Int {
  if total_shares == 0 {
    // Primera liquidez: shares = amount depositado
    // Podría usar sqrt(ada * tokens) para más precisión
    deposited_ada
  } else {
    // Shares proporcionales a la liquidez existente
    ( deposited_ada * total_shares ) / ada_reserve
  }
}

/// Calcula cantidad a devolver al retirar liquidez
/// Formula: amount = (reserve * shares) / total_shares
/// 
/// # Argumentos
/// * `reserve` - Reserva actual (ADA o tokens)
/// * `total_shares` - Total de shares en circulación
/// * `shares_amount` - Cantidad de shares a quemar
/// 
/// # Retorna
/// * Cantidad a devolver de la reserva
pub fn calculate_liquidity_withdrawal(
  reserve: Int,
  total_shares: Int,
  shares_amount: Int,
) -> Int {
  ( reserve * shares_amount ) / total_shares
}

// ============================================
// CÁLCULOS DE PRECIO
// ============================================

/// Calcula el precio de un token en términos de ADA
/// 
/// # Argumentos
/// * `ada_reserve` - Reserva de ADA
/// * `token_reserve` - Reserva de tokens
/// 
/// # Retorna
/// * Precio con 6 decimales de precisión
pub fn calculate_token_price(
  ada_reserve: Int,
  token_reserve: Int,
) -> Int {
  // Precio = ada_reserve / token_reserve
  // Multiplicar por precision_multiplier para mantener decimales
  ( ada_reserve * 1_000_000 ) / token_reserve
}

/// Calcula el impacto en el precio de un swap
/// 
/// # Argumentos
/// * `reserve` - Reserva correspondiente al asset de entrada
/// * `amount_in` - Cantidad que entra
/// 
/// # Retorna
/// * Impacto en porcentaje (con 2 decimales: 1550 = 15.50%)
pub fn calculate_price_impact(
  reserve: Int,
  amount_in: Int,
) -> Int {
  // Impact = (amount_in / reserve) * 10000
  // Resultado en basis points (10000 = 100%)
  ( amount_in * 10000 ) / reserve
}

// ============================================
// VALIDACIONES DE FÓRMULA
// ============================================

/// Verifica que el producto constante se mantenga después de un swap
/// 
/// # Argumentos
/// * `old_ada` - Reserva de ADA antes del swap
/// * `old_tokens` - Reserva de tokens antes del swap
/// * `new_ada` - Reserva de ADA después del swap
/// * `new_tokens` - Reserva de tokens después del swap
/// * `fee_bps` - Fee aplicado
/// 
/// # Retorna
/// * True si k se mantiene o aumenta (con fee)
pub fn verify_constant_product(
  old_ada: Int,
  old_tokens: Int,
  new_ada: Int,
  new_tokens: Int,
  fee_bps: Int,
) -> Bool {
  // k_old = old_ada * old_tokens
  let k_old = old_ada * old_tokens
  
  // k_new = new_ada * new_tokens
  let k_new = new_ada * new_tokens
  
  // Con fees, k_new debería ser >= k_old
  // Permitir pequeña tolerancia por redondeo
  let tolerance = k_old / 10000 // 0.01%
  
  k_new >= k_old - tolerance
}

// ============================================
// TESTS
// ============================================

test calculate_token_output_test() {
  // Pool: 1000 ADA, 10000 Tokens, Fee: 0.3%
  let token_reserve = 10000000000 // 10000 tokens
  let ada_reserve = 1000000000 // 1000 ADA
  let ada_in = 100000000 // 100 ADA
  let fee_bps = 30 // 0.3%
  
  let tokens_out = calculate_token_output(
    token_reserve,
    ada_reserve,
    ada_in,
    fee_bps,
  )
  
  // Debería recibir aproximadamente 906 tokens
  tokens_out > 900000000 && tokens_out < 910000000
}

test calculate_shares_first_liquidity() {
  let shares = calculate_shares(0, 0, 1000000000)
  shares == 1000000000
}

test calculate_shares_subsequent() {
  // Pool: 1000 ADA, 100 shares
  // Depositar 100 ADA debe dar 10 shares
  let shares = calculate_shares(100, 1000000000, 100000000)
  shares == 10
}

test price_impact_calculation() {
  // Swap 100 ADA en pool de 1000 ADA = 10% impact
  let impact = calculate_price_impact(1000000000, 100000000)
  impact == 1000 // 10% = 1000 bps
}