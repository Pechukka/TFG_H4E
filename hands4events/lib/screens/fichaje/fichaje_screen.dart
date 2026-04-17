import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_custom.dart';

/// Pantalla básica de fichaje para eventos.
class FichajeScreen extends StatelessWidget {
	final String tituloEvento;
	final String fecha;

	const FichajeScreen({
		super.key,
		this.tituloEvento = 'Fichaje',
		this.fecha = '',
	});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppTheme.fondoPrincipal,
			appBar: AppBarCustom(
				showLogo: true,
				showBackButton: true,
				title: tituloEvento,
			),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Center(
						child: Container(
							width: double.infinity,
							padding: const EdgeInsets.all(24),
							decoration: BoxDecoration(
								color: AppTheme.fondoCard,
								borderRadius: BorderRadius.circular(12),
							),
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									const Icon(
										Icons.access_time_filled_rounded,
										size: 46,
										color: AppTheme.verdeNeon,
									),
									const SizedBox(height: 16),
									Text(
										'Esta es la pantalla de fichaje',
										style: Theme.of(context).textTheme.titleLarge,
										textAlign: TextAlign.center,
									),
									if (fecha.isNotEmpty) ...[
										const SizedBox(height: 8),
										Text(
											fecha,
											style: Theme.of(context).textTheme.bodySmall?.copyWith(
												color: AppTheme.textoSecundario,
											),
											textAlign: TextAlign.center,
										),
									],
								],
							),
						),
					),
				),
			),
		);
	}
}
