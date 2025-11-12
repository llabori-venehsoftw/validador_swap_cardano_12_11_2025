// ============================================
// lib/math/utils.ak
// Utilidades matemáticas generales
// ============================================

use swap_inicial/lib/constants.{precision_multiplier}

// ============================================
// OPERACIONES BÁSICAS
// ============================================

/// Calcula la diferencia absoluta entre dos números
/// 
/// # Argumentos
/// * `a` - Primer número
/// * `b` - Segundo número
/// 
/// # Retorna
/// * |a - b|
pub fn abs_difference(a: Int, b: Int) -> Int {
  if a > b {
    a - b
  } else {
    b - a
  }
}

/// Calcula el valor absoluto de un número
/// 
/// # Argumentos
/// * `n` - Número
/// 
/// # Retorna
/// * |n|
pub fn abs(n: Int) -> Int {
  if n < 0 {
    -n
  } else {
    n
  }
}

/// Calcula el mínimo entre dos números
/// 
/// # Argumentos
/// * `a` - Primer número
/// * `b` - Segundo número
/// 
/// # Retorna
/// * min(a, b)
pub fn min(a: Int, b: Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

/// Calcula el máximo entre dos números
/// 
/// # Argumentos
/// * `a` - Primer número
/// * `b` - Segundo número
/// 
/// # Retorna
/// * max(a, b)
pub fn max(a: Int, b: Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

// ============================================
// OPERACIONES CON RATIOS
// ============================================

/// Calcula el ratio entre dos cantidades con precisión
/// 
/// # Argumentos
/// * `numerator` - Numerador
/// * `denominator` - Denominador
/// 
/// # Retorna
/// * Ratio con 6 decimales de precisión
pub fn calculate_ratio(numerator: Int, denominator: Int) -> Int {
  ( numerator * precision_multiplier ) / denominator
}

/// Verifica si dos ratios son aproximadamente iguales (con tolerancia)
/// 
/// # Argumentos
/// * `ratio1` - Primer ratio
/// * `ratio2` - Segundo ratio
/// * `tolerance_bps` - Tolerancia en basis points (100 = 1%)
/// 
/// # Retorna
/// * True si los ratios están dentro de la tolerancia
pub fn ratios_approximately_equal(
  ratio1: Int,
  ratio2: Int,
  tolerance_bps: Int,
) -> Bool {
  let difference = abs_difference(ratio1, ratio2)
  let max_difference = ( ratio1 * tolerance_bps ) / 10000
  
  difference <= max_difference
}

// ============================================
// OPERACIONES CON PORCENTAJES
// ============================================

/// Calcula el X% de un valor
/// 
/// # Argumentos
/// * `value` - Valor base
/// * `percentage_bps` - Porcentaje en basis points (100 = 1%)
/// 
/// # Retorna
/// * X% del valor
pub fn percentage_of(value: Int, percentage_bps: Int) -> Int {
  ( value * percentage_bps ) / 10000
}

/// Aplica un incremento porcentual a un valor
/// 
/// # Argumentos
/// * `value` - Valor base
/// * `increase_bps` - Incremento en basis points
/// 
/// # Retorna
/// * valor * (1 + incremento)
pub fn apply_percentage_increase(value: Int, increase_bps: Int) -> Int {
  value + percentage_of(value, increase_bps)
}

/// Aplica un decremento porcentual a un valor
/// 
/// # Argumentos
/// * `value` - Valor base
/// * `decrease_bps` - Decremento en basis points
/// 
/// # Retorna
/// * valor * (1 - decremento)
pub fn apply_percentage_decrease(value: Int, decrease_bps: Int) -> Int {
  value - percentage_of(value, decrease_bps)
}

// ============================================
// VALIDACIONES NUMÉRICAS
// ============================================

/// Verifica que un valor esté dentro de un rango
/// 
/// # Argumentos
/// * `value` - Valor a verificar
/// * `min_value` - Mínimo (inclusivo)
/// * `max_value` - Máximo (inclusivo)
/// 
/// # Retorna
/// * True si min <= value <= max
pub fn within_range(value: Int, min_value: Int, max_value: Int) -> Bool {
  and {
    value >= min_value,
    value <= max_value,
  }
}

/// Verifica que un valor sea positivo
pub fn is_positive(value: Int) -> Bool {
  value > 0
}

/// Verifica que un valor sea no negativo
pub fn is_non_negative(value: Int) -> Bool {
  value >= 0
}

// ============================================
// OPERACIONES SEGURAS
// ============================================

/// División segura que verifica que el denominador no sea cero
/// 
/// # Argumentos
/// * `numerator` - Numerador
/// * `denominator` - Denominador
/// 
/// # Retorna
/// * Some(result) si denominador != 0, None en otro caso
pub fn safe_divide(numerator: Int, denominator: Int) -> Option<Int> {
  if denominator == 0 {
    None
  } else {
    Some(numerator / denominator)
  }
}

/// Multiplicación con verificación de overflow
/// Simplificado: asume que no habrá overflow en el contexto del swap
/// 
/// # Argumentos
/// * `a` - Primer factor
/// * `b` - Segundo factor
/// 
/// # Retorna
/// * a * b
pub fn safe_multiply(a: Int, b: Int) -> Int {
  // En producción, implementar verificación de overflow
  a * b
}

// ============================================
// REDONDEO
// ============================================

/// Redondea hacia abajo
pub fn floor_divide(numerator: Int, denominator: Int) -> Int {
  numerator / denominator
}

/// Redondea hacia arriba
pub fn ceil_divide(numerator: Int, denominator: Int) -> Int {
  let quotient = numerator / denominator
  let remainder = numerator % denominator
  
  if remainder > 0 {
    quotient + 1
  } else {
    quotient
  }
}

// ============================================
// TESTS
// ============================================

test abs_difference_test() {
  and {
    abs_difference(10, 5) == 5,
    abs_difference(5, 10) == 5,
    abs_difference(7, 7) == 0,
  }
}

test ratio_calculation_test() {
  // Ratio 1:10 con precisión
  let ratio = calculate_ratio(100000000, 1000000000)
  ratio == 100000 // 0.1 con 6 decimales
}

test percentage_calculation_test() {
  // 1% de 1000 = 10
  let result = percentage_of(1000, 100)
  result == 10
}

test safe_divide_test() {
  and {
    safe_divide(10, 2) == Some(5),
    safe_divide(10, 0) == None,
  }
}