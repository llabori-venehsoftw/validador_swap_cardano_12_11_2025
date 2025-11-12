// ============================================
// lib/types.ak
// Tipos de datos compartidos
// ============================================

use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value.{AssetName, PolicyId}

// ============================================
// DATUM DEL POOL
// ============================================

/// Datum del pool de liquidez
pub type PoolDatum {
  /// Token que se intercambia (Policy ID)
  token_policy: PolicyId,
  /// Nombre del token
  token_name: AssetName,
  /// Cantidad de tokens en el pool
  token_reserve: Int,
  /// Cantidad de ADA en el pool (lovelace)
  ada_reserve: Int,
  /// Fee en basis points (30 = 0.3%)
  fee_bps: Int,
  /// Propietario del pool (puede retirar)
  pool_owner: Hash<Blake2b_224, VerificationKey>,
  /// Total de shares emitidos (para LP tokens)
  total_shares: Int,
}

// ============================================
// REDEEMER
// ============================================

/// Redeemer para operaciones del pool
pub type SwapRedeemer {
  /// Swap: ADA → Token
  SwapAdaForToken {
    /// Cantidad mínima de tokens a recibir (slippage protection)
    min_token_out: Int,
  }
  /// Swap: Token → ADA
  SwapTokenForAda {
    /// Cantidad mínima de ADA a recibir (slippage protection)
    min_ada_out: Int,
  }
  /// Agregar liquidez al pool
  AddLiquidity {
    /// Cantidad de ADA a depositar
    ada_amount: Int,
    /// Cantidad de tokens a depositar
    token_amount: Int,
  }
  /// Remover liquidez del pool
  RemoveLiquidity {
    /// Cantidad de shares a quemar
    shares_amount: Int,
  }
  /// Cerrar el pool (solo owner)
  ClosePool
}

// ============================================
// TIPOS AUXILIARES
// ============================================

/// Resultado de un cálculo de swap
pub type SwapCalculation {
  /// Cantidad de salida calculada
  output_amount: Int,
  /// Fee aplicado
  fee_amount: Int,
  /// Nuevo estado de las reservas
  new_token_reserve: Int,
  new_ada_reserve: Int,
}

/// Resultado de un cálculo de liquidez
pub type LiquidityCalculation {
  /// Cantidad de ADA a depositar/retirar
  ada_amount: Int,
  /// Cantidad de tokens a depositar/retirar
  token_amount: Int,
  /// Shares a emitir/quemar
  shares_amount: Int,
}

/// Información de cambios en el pool
pub type PoolChange {
  /// Cambio en reserva de ADA (puede ser negativo)
  ada_delta: Int,
  /// Cambio en reserva de tokens (puede ser negativo)
  token_delta: Int,
  /// Cambio en shares (puede ser negativo)
  shares_delta: Int,
}