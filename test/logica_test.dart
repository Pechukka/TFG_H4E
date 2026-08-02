import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hands4events/core/roles.dart';
import 'package:hands4events/models/fichaje.dart';
import 'package:hands4events/screens/admin/eventos/activar_evento.dart';

// Tests de la lógica pura (sin Firebase): tarifas, horas netas de fichaje y
// cobertura del equipo. Cubren los cálculos críticos de nómina y activación.
void main() {
  group('RolesEvento.tarifaDe', () {
    test('roles conocidos devuelven su tarifa', () {
      expect(RolesEvento.tarifaDe('H4ndMontaje'), 8.0);
      expect(RolesEvento.tarifaDe('H4ndDesmontaje'), 7.5);
      expect(RolesEvento.tarifaDe('Coordinador'), 10.0);
      expect(RolesEvento.tarifaDe('Runner'), 9.0);
    });
    test('rol desconocido o vacío → 0', () {
      expect(RolesEvento.tarifaDe('Inexistente'), 0.0);
      expect(RolesEvento.tarifaDe(''), 0.0);
    });
  });

  group('Fichaje.horasNetas', () {
    Timestamp ts(int h, int m) => Timestamp.fromDate(DateTime(2026, 1, 1, h, m));

    test('sin pausas: bruto == neto', () {
      final data = {'entrada': ts(8, 0), 'salida': ts(16, 0), 'pausas': []};
      expect(Fichaje.horasNetas(data), 8.0);
    });
    test('descuenta una pausa de 30 min', () {
      final data = {
        'entrada': ts(8, 0),
        'salida': ts(16, 0),
        'pausas': [
          {'inicio': ts(12, 0), 'fin': ts(12, 30)}
        ],
      };
      expect(Fichaje.horasNetas(data), 7.5);
    });
    test('descuenta varias pausas', () {
      final data = {
        'entrada': ts(8, 0),
        'salida': ts(18, 0),
        'pausas': [
          {'inicio': ts(11, 0), 'fin': ts(11, 15)},
          {'inicio': ts(14, 0), 'fin': ts(15, 0)},
        ],
      };
      // 10h - 15min - 60min = 8.75h
      expect(Fichaje.horasNetas(data), 8.75);
    });
    test('pausa abierta (sin fin) se corta en la salida', () {
      final data = {
        'entrada': ts(8, 0),
        'salida': ts(16, 0),
        'pausas': [
          {'inicio': ts(15, 0), 'fin': null}
        ],
      };
      expect(Fichaje.horasNetas(data), 7.0);
    });
    test('sin salida → 0 (fichaje no cerrado)', () {
      final data = {'entrada': ts(8, 0), 'salida': null, 'pausas': []};
      expect(Fichaje.horasNetas(data), 0.0);
    });
    test('nunca negativo aunque los datos sean inconsistentes', () {
      final data = {
        'entrada': ts(8, 0),
        'salida': ts(9, 0),
        'pausas': [
          {'inicio': ts(8, 0), 'fin': ts(11, 0)} // pausa mayor que el intervalo
        ],
      };
      expect(Fichaje.horasNetas(data), 0.0);
    });
  });

  group('faltantesPorRol (cobertura del equipo)', () {
    test('cuenta faltantes por rol excluyendo al admin creador', () {
      final data = {
        'plazasPorRol': {'H4ndMontaje': 3, 'Coordinador': 1},
        'trabajadoresRoles': {
          'admin1': 'Coordinador', // creador → NO cuenta
          'w1': 'H4ndMontaje',
          'w2': 'H4ndMontaje',
        },
        'creadoPor': 'admin1',
      };
      final faltan = faltantesPorRol(data);
      expect(faltan['H4ndMontaje'], 1); // 3 objetivo - 2 confirmados
      // El admin no cuenta como Coordinador → sigue faltando 1.
      expect(faltan['Coordinador'], 1);
    });

    test('equipo completo → sin faltantes', () {
      final data = {
        'plazasPorRol': {'Runner': 2},
        'trabajadoresRoles': {
          'admin1': 'Coordinador',
          'w1': 'Runner',
          'w2': 'Runner',
        },
        'creadoPor': 'admin1',
      };
      expect(faltantesPorRol(data), isEmpty);
    });

    test('rol sobrecubierto no aparece como faltante (no negativo)', () {
      final data = {
        'plazasPorRol': {'Runner': 1},
        'trabajadoresRoles': {'w1': 'Runner', 'w2': 'Runner'},
        'creadoPor': 'admin1',
      };
      expect(faltantesPorRol(data), isEmpty);
    });
  });
}
