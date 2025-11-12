💱 Swap DEX - Token ↔ ADA Exchange
Sistema completo de intercambio descentralizado (DEX) en Cardano usando Automated Market Maker (AMM) con fórmula de producto constante.
🎯 Características
Operaciones Soportadas

✅ Swap ADA → Token: Intercambiar ADA por tokens
✅ Swap Token → ADA: Intercambiar tokens por ADA
✅ Add Liquidity: Depositar liquidez y recibir LP shares
✅ Remove Liquidity: Retirar liquidez quemando LP shares
✅ Pool Management: Crear y cerrar pools

Seguridad

✅ Slippage Protection: Protección contra deslizamiento de precio
✅ Price Impact Calculation: Cálculo de impacto en el precio
✅ AMM Formula: x * y = k (producto constante)
✅ Fee System: Comisiones configurables
✅ Ratio Validation: Validación de ratios de liquidez

📐 Fórmula AMM (Automated Market Maker)
Producto Constante
x * y = k

Donde:
- x = reserva de ADA
- y = reserva de tokens
- k = constante (invariante)
Cálculo de Swap (ADA → Token)
token_out = (token_reserve * ada_in * (10000 - fee)) / 
            ((ada_reserve * 10000) + (ada_in * (10000 - fee)))

Ejemplo:
Pool: 1000 ADA, 10000 Tokens, Fee: 0.3%
Input: 100 ADA
Output: (10000 * 100 * 9970) / ((1000 * 10000) + (100 * 9970))
      = 9970000000 / 10997000
      ≈ 906.8 tokens
Cálculo de Swap (Token → ADA)
ada_out = (ada_reserve * token_in * (10000 - fee)) / 
          ((token_reserve * 10000) + (token_in * (10000 - fee)))
Shares de Liquidez
shares = (deposited_ada / ada_reserve) * total_shares

Primera liquidez:
shares = deposited_ada
🏗️ Arquitectura
┌─────────────────────────────────────────────────────────┐
│                    LIQUIDITY POOL                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │ ADA Reserve: 1000 ADA                          │  │
│  │ Token Reserve: 10000 TOKENS                     │  │
│  │ Fee: 0.3%                                       │  │
│  │ Total Shares: 1000                              │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
           │
           ├── SwapAdaForToken
           │   └─> Input: 100 ADA
           │   └─> Output: ~906 Tokens
           │   └─> Fee: 0.3 ADA
           │   └─> Price Impact: 10%
           │
           ├── SwapTokenForAda
           │   └─> Input: 1000 Tokens
           │   └─> Output: ~90.6 ADA
           │   └─> Fee: 3 Tokens
           │   └─> Price Impact: 10%
           │
           ├── AddLiquidity
           │   └─> Deposit: 100 ADA + 1000 Tokens
           │   └─> Receive: 100 LP Shares
           │   └─> Ratio: 1:10 maintained
           │
           └── RemoveLiquidity
               └─> Burn: 100 LP Shares
               └─> Receive: ~100 ADA + ~1000 Tokens
               └─> Proportional to share %
📦 Estructura del Proyecto
swap-dex/
├── validators/
│   └── swap.ak                # ⭐ Validador AMM
├── scripts/
│   └── swap-manager.js        # ⭐ Manager completo
├── pools/
│   └── pool_[tokenId].json   # Info de pools
└── plutus.json
🚀 Setup
1. Compilar Validador
bashcd swap-dex
aiken build
aiken check
2. Instalar Dependencias
bashcd scripts
npm install
3. Configurar Environment
bash# .env
BLOCKFROST_API_KEY=preprodYourAPIKey
WALLET_MNEMONIC="your mnemonic here"
💻 Uso
Crear Pool
javascriptimport { SwapManager } from './swap-manager.js';

const manager = new SwapManager(wallet);

// Crear pool con liquidez inicial
await manager.createPool(
  tokenPolicyId,        // Policy ID del token
  tokenName,            // Nombre (hex)
  1000_000_000,         // 1000 ADA inicial
  10000_000_000,        // 10000 tokens iniciales
  30                    // 0.3% fee
);
Obtener Cotización
javascript// Cotizar 100 ADA → Token
const quote = await manager.getQuote('ADA', 'TOKEN', 100_000_000);

console.log(quote);
// {
//   input: 100,
//   output: 906.8,
//   fee: 0.3,
//   priceImpact: "10.00%",
//   minimumReceived: 901.76
// }
Swap ADA → Token
javascriptconst adaAmount = 100_000_000; // 100 ADA
const minTokenOut = 900_000_000; // Mínimo 900 tokens (slippage 1%)

await manager.swapAdaForToken(adaAmount, minTokenOut);

// Resultado:
// ✅ Recibiste ~906 tokens
// ✅ Pagaste 0.3 ADA de fee
// ✅ Impacto en precio: 10%
Swap Token → ADA
javascriptconst tokenAmount = 1000_000_000; // 1000 tokens
const minAdaOut = 90_000_000;     // Mínimo 90 ADA

await manager.swapTokenForAda(tokenAmount, minAdaOut);

// Resultado:
// ✅ Recibiste ~90.6 ADA
// ✅ Pagaste ~3 tokens de fee
Agregar Liquidez
javascript// Depositar liquidez proporcional
await manager.addLiquidity(
  100_000_000,   // 100 ADA
  1000_000_000   // 1000 tokens (ratio 1:10)
);

// Resultado:
// ✅ Recibiste 100 LP shares
// ✅ Ahora eres proveedor de liquidez
// ✅ Ganas comisiones de los swaps
Ver Info del Pool
javascriptconst info = await manager.getPoolInfo();

console.log(info);
// {
//   tokenReserve: 10000,
//   adaReserve: 1000,
//   feeBps: 30,
//   feePercentage: 0.3,
//   totalShares: 1000,
//   priceTokenInAda: 0.1,
//   priceAdaInToken: 10,
//   tvl: 2000
// }
🔒 Validaciones del Validador
Swap ADA → Token
rust✅ ada_in > 0
✅ tokens_out >= min_token_out (slippage protection)
✅ tokens_out == calculated_output (AMM formula)
✅ Reservas actualizadas correctamente:
   - ada_reserve += ada_in
   - token_reserve -= tokens_out
✅ Resto del datum sin cambios
Swap Token → ADA
rust✅ tokens_in > 0
✅ ada_out >= min_ada_out (slippage protection)
✅ ada_out == calculated_output (AMM formula)
✅ Reservas actualizadas correctamente:
   - token_reserve += tokens_in
   - ada_reserve -= ada_out
✅ Resto del datum sin cambios
Add Liquidity
rust✅ deposited_ada > 0 && deposited_tokens > 0
✅ Ratio válido (dentro del 1% del ratio del pool)
✅ Shares calculados correctamente
✅ Reservas y shares actualizados
Remove Liquidity
rust✅ shares_amount > 0
✅ Cantidades devueltas proporcionales a shares
✅ Reservas y shares actualizados
Close Pool
rust✅ Firmado por pool_owner
✅ No hay output de continuación
📊 Estructura de Datos
PoolDatum
rust{
  token_policy: PolicyId,      // Policy del token
  token_name: AssetName,       // Nombre del token
  token_reserve: Int,          // Tokens en el pool
  ada_reserve: Int,            // ADA en el pool (lovelace)
  fee_bps: Int,                // Fee en basis points (30 = 0.3%)
  pool_owner: Hash,            // PKH del propietario
  total_shares: Int,           // Total de LP shares
}
Redeemers
rustSwapAdaForToken { min_token_out: Int }
SwapTokenForAda { min_ada_out: Int }
AddLiquidity { ada_amount: Int, token_amount: Int }
RemoveLiquidity { shares_amount: Int }
ClosePool
💰 Economía del Pool
Fees

Default: 0.3% (30 basis points)
Configurable por pool
Distribuidos a proveedores de liquidez

Price Impact
impact = (amount_in / reserve) * 100

Ejemplo:
- Swap 100 ADA en pool de 1000 ADA
- Impact = (100 / 1000) * 100 = 10%
Slippage
slippage = ((expected - received) / expected) * 100

Protección:
- Usuario especifica min_out
- Transacción falla si slippage > tolerancia
Arbitraje
Si precio_pool ≠ precio_mercado:
- Arbitrajistas compran barato, venden caro
- Esto balancea el precio del pool
- Pool converge al precio de mercado
🧪 Testing
Tests de Aiken
bashaiken check -v

# Tests específicos
aiken check -m "swap_ada_for_token"
aiken check -m "swap_token_for_ada"
aiken check -m "liquidity_ratio"
Casos de Test

Swap ADA → Token

✅ Cantidad correcta según AMM
✅ Fee aplicado correctamente
❌ Slippage excedido
❌ Reservas insuficientes


Swap Token → ADA

✅ Cantidad correcta según AMM
✅ Fee aplicado correctamente
❌ Slippage excedido


Add Liquidity

✅ Ratio correcto (1:10)
❌ Ratio incorrecto (1:5)
✅ Shares calculados correctamente


Remove Liquidity

✅ Cantidades proporcionales
❌ Más shares de los que posee



💡 Casos de Uso
1. Trading Simple
javascript// Usuario quiere cambiar 50 ADA por tokens
const quote = await manager.getQuote('ADA', 'TOKEN', 50_000_000);
console.log('Recibirás:', quote.output, 'tokens');

if (quote.priceImpact < '5%') {
  await manager.swapAdaForToken(50_000_000, quote.minimumReceived * 1_000_000);
}
2. Proveer Liquidez
javascript// Usuario quiere ganar fees siendo LP
await manager.addLiquidity(
  500_000_000,   // 500 ADA
  5000_000_000   // 5000 tokens
);

// Ahora gana 0.3% de todos los swaps
3. Market Making
javascript// Bot de arbitraje
const externalPrice = 0.11; // Token vale 0.11 ADA en otro exchange
const poolInfo = await manager.getPoolInfo();

if (poolInfo.priceTokenInAda < externalPrice) {
  // Comprar tokens en el pool (baratos)
  await manager.swapAdaForToken(amount, minOut);
  // Vender en exchange externo (caro)
}
4. Retiro de Liquidez
javascript// Usuario quiere retirar su liquidez
await manager.removeLiquidity(
  100_000_000 // 100 LP shares
);

// Recibe ADA + tokens proporcionalmente
📈 Métricas del Pool
javascriptconst metrics = await manager.getPoolInfo();

console.log(`
TVL: ${metrics.tvl} ADA
Token Price: ${metrics.priceTokenInAda} ADA
ADA Price: ${metrics.priceAdaInToken} Tokens
Fee Rate: ${metrics.feePercentage}%
Total Shares: ${metrics.totalShares}
`);
🔐 Seguridad
Garantías

Producto Constante: x * y = k siempre se mantiene
Atomicidad: Todas las operaciones son atómicas
Slippage Protection: Usuario controla salida mínima
Ratio Validation: Liquidez debe mantener proporción

Ataques Prevenidos

❌ Front-running: Slippage protection mitiga
❌ Sandwich attacks: Min_out protege al usuario
❌ Price manipulation: Ratio validation en liquidez
❌ Impermanent loss: Inherente al AMM, pero calculable

📚 Referencias

Uniswap V2 Whitepaper
AMM Basics
Aiken Documentation
MeshJS Documentation

🚀 Mejoras Futuras

 Multi-asset pools (más de 2 tokens)
 Concentrated liquidity (Uniswap V3 style)
 Time-weighted average price (TWAP)
 Flash swaps
 Governance token
 Fee tiers
 Limit orders

💰 Costos Estimados
OperaciónCosto AproximadoCrear Pool~2-3 ADASwap~0.5-1 ADAAdd Liquidity~0.5-1 ADARemove Liquidity~0.5-1 ADA
⚠️ Disclaimer
Este código es para propósitos educativos. Antes de usar en mainnet:

✅ Auditar completamente
✅ Probar en testnet extensivamente
✅ Revisar economía del pool
✅ Considerar impermanent loss
✅ Entender riesgos de liquidez


📝 Licencia
MIT-1.0