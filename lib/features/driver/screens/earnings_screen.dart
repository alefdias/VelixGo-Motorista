import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/driver_controller.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  void _showPixPaymentModal(BuildContext context, InvoiceModel invoice, DriverController driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: AppColors.green, size: 28),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pagar Fatura Velix via Pix',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Valor da fatura: ${Formatters.formatCurrency(invoice.amount)}',
                style: const TextStyle(fontSize: 14, color: AppColors.grey),
              ),
              const SizedBox(height: 20),

              // QR Code Pix
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                  ],
                ),
                child: QrImageView(
                  data: invoice.pixCopyPaste,
                  version: QrVersions.auto,
                  size: 190.0,
                ),
              ),
              const SizedBox(height: 20),

              // Pix Copia e Cola
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.pixCopyPaste,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: AppColors.blue),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: invoice.pixCopyPaste));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.blue,
                            content: Text('Código Pix Copia e Cola copiado!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botão Simular Pagamento Concluído
              ElevatedButton.icon(
                onPressed: () async {
                  await driver.payInvoicePix(invoice.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.green,
                        content: Text('Pagamento Pix confirmado! Fatura quitada.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Já Efetuei o Pagamento Pix'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = Provider.of<DriverController>(context);

    final currentBalance = driver.velixBalance;
    final progressToLimit = (currentBalance / AppConstants.autoInvoiceThreshold).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Ganhos & Saldo Velix'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Painel de Ganhos: Hoje, Semana, Mês
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ganhos Brutos (100% recebidos)',
                  style: TextStyle(color: AppColors.greyLight, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.formatCurrency(driver.earningsToday),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderDark),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _EarningsColumn(
                      title: 'Esta Semana',
                      amount: driver.earningsWeek,
                    ),
                    _EarningsColumn(
                      title: 'Este Mês',
                      amount: driver.earningsMonth,
                    ),
                    _EarningsColumn(
                      title: 'Total Viagens',
                      amount: (driver.driverProfile?.totalRides ?? 48).toDouble(),
                      isCounter: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seção Saldo Velix (Taxa R$ 0,50 e Cobrança Automática)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.blue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saldo Velix',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                              ),
                              Text(
                                'Taxas acumuladas (R\$ 0,50/corrida)',
                                style: TextStyle(color: AppColors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatCurrency(currentBalance),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: currentBalance > 15 ? AppColors.red : AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barra de Progresso até R$ 20,00
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressToLimit,
                      minHeight: 8,
                      color: progressToLimit > 0.8 ? AppColors.red : AppColors.blue,
                      backgroundColor: AppColors.surfaceLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Atual: ${Formatters.formatCurrency(currentBalance)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.grey),
                      ),
                      const Text(
                        'Limite fatura: R\$ 20,00',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Regra Automática explicativa
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppColors.grey),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Regra Automática: A fatura é gerada quando o saldo atingir R\$ 20,00 OU ao completar 15 dias da última cobrança.',
                            style: TextStyle(fontSize: 12, color: AppColors.grey, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Faturas do Saldo Velix (Invoices)
          const Text(
            'Faturas e Cobranças Pix',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.black),
          ),
          const SizedBox(height: 10),

          if (driver.invoices.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('Nenhuma fatura gerada no momento.', style: TextStyle(color: AppColors.grey)),
            )
          else
            ...driver.invoices.map((inv) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: inv.isPaid ? AppColors.green.withOpacity(0.12) : AppColors.red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          inv.isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
                          color: inv.isPaid ? AppColors.green : AppColors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fatura ${inv.id.substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              inv.isPaid
                                  ? 'Paga em ${Formatters.formatSimpleDate(inv.paidAt ?? inv.createdAt)}'
                                  : 'Vence em ${Formatters.formatSimpleDate(inv.dueDate)}',
                              style: const TextStyle(color: AppColors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCurrency(inv.amount),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          if (inv.isPending)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(80, 32),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                backgroundColor: AppColors.green,
                              ),
                              onPressed: () => _showPixPaymentModal(context, inv, driver),
                              child: const Text('Pagar Pix', style: TextStyle(fontSize: 12)),
                            )
                          else
                            const Text(
                              'Quitada',
                              style: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _EarningsColumn extends StatelessWidget {
  final String title;
  final double amount;
  final bool isCounter;

  const _EarningsColumn({
    required this.title,
    required this.amount,
    this.isCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.greyLight, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          isCounter ? amount.toInt().toString() : Formatters.formatCurrency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
