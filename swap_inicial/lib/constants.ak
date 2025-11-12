// ============================================
// lib/constants.ak
// Constantes del sistema
// ============================================

/// Multiplicador para cálculos de precisión (6 decimales)
pub const precision_multiplier: Int = 1000000

/// Mínimo de liquidez inicial para evitar manipulación
pub const minimum_liquidity: Int = 1000

/// Base de cálculo para basis points (100 bps = 1%)
pub const basis_points_base: Int = 10000

/// Fee máximo permitido (10% = 1000 bps)
pub const max_fee_bps: Int = 1000

/// Fee mínimo permitido (0.01% = 1 bp)
pub const min_fee_bps: Int = 1

/// Tolerancia máxima para ratio de liquidez (1%)
pub const max_ratio_tolerance_percent: Int = 1

/// Mínimo ADA en el pool para prevenir división por cero
pub const min_ada_reserve: Int = 1000000 // 1 ADA

/// Mínimo de tokens en el pool
pub const min_token_reserve: Int = 1000000 // Depende del token

/// Máximo slippage permitido por defecto (5%)
pub const default_max_slippage_percent: Int = 5