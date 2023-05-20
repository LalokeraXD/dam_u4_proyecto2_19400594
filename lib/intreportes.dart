import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';

class IntReportes extends StatefulWidget {
  const IntReportes({Key? key}) : super(key: key);

  @override
  State<IntReportes> createState() => _IntReportesState();
}

class _IntReportesState extends State<IntReportes> {
  final _docenteConsultaController = TextEditingController();
  final _edificioConsultaController = TextEditingController();
  final _revisorConsultaController = TextEditingController();

  final _fechaIniConsultaController = TextEditingController();
  late DateTime _selectedFechaIni;
  final _fechaFinConsultaController = TextEditingController();
  late DateTime _selectedFechaFin;

  String? _selectedEdificio;

  final List<String> _opcionesConsulta = [
    'asistenciaPorDocente',
    'asistenciaPorFechas',
    'asistenciaPorFechasYEdificio',
    'asistenciaPorRevisor',
  ];

  String _selectedConsulta = 'asistenciaPorDocente';
  List<Map<String, dynamic>> _resultados = [];

  @override
  void dispose() {
    _docenteConsultaController.dispose();
    _fechaIniConsultaController.dispose();
    _fechaFinConsultaController.dispose();
    _edificioConsultaController.dispose();
    _revisorConsultaController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedFechaIni = DateTime.now();
    _fechaIniConsultaController.text =
        DateFormat('dd/MM/yyyy').format(_selectedFechaIni);
    _selectedFechaFin = DateTime.now();
    _fechaFinConsultaController.text =
        DateFormat('dd/MM/yyyy').format(_selectedFechaFin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reportes',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 55,
      ),
      body: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedConsulta,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedConsulta = newValue!;
                });
              },
              items: _opcionesConsulta.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Tipo de consulta',
              ),
            ),
            SizedBox(height: 16.0),
            if (_selectedConsulta == 'asistenciaPorDocente')
              TextFormField(
                controller: _docenteConsultaController,
                decoration: InputDecoration(labelText: 'Docente'),
              ),
            if (_selectedConsulta == 'asistenciaPorFechas')
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                    controller: _fechaIniConsultaController,
                    onTap: () {
                      _selectFechaIni(context);
                    },
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha inicial',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  )),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                      child: TextFormField(
                    controller: _fechaFinConsultaController,
                    onTap: () {
                      _selectFechaFin(context);
                    },
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha final',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  )),
                ],
              ),
            if (_selectedConsulta == 'asistenciaPorFechasYEdificio')
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fechaIniConsultaController,
                      onTap: () {
                        _selectFechaIni(context);
                      },
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fecha inicial',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _fechaFinConsultaController,
                      onTap: () {
                        _selectFechaFin(context);
                      },
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fecha final',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedEdificio,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedEdificio = newValue;
                        });
                      },
                      items: [
                        DropdownMenuItem<String>(
                          value: 'A',
                          child: Text('Edificio A'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'X',
                          child: Text('Edificio X'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'UD',
                          child: Text('Edificio UD'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Edificio',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor selecciona el edificio.';
                        }
                        return null;
                      },
                    ),
                  )
                ],
              ),
            if (_selectedConsulta == 'asistenciaPorRevisor')
              TextFormField(
                controller: _revisorConsultaController,
                decoration: InputDecoration(labelText: 'Revisor'),
              ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _realizarConsulta,
              child: Text('Realizar consulta'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: _buildResultados(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFechaIni(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFechaIni,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedFechaIni) {
      setState(() {
        _selectedFechaIni = pickedDate;
        _fechaIniConsultaController.text =
            DateFormat('dd/MM/yyyy').format(_selectedFechaIni);
      });
    }
  }

  Future<void> _selectFechaFin(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFechaFin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedFechaFin) {
      setState(() {
        _selectedFechaFin = pickedDate;
        _fechaFinConsultaController.text =
            DateFormat('dd/MM/yyyy').format(_selectedFechaFin);
      });
    }
  }

  Widget _buildResultados() {
    if (_resultados.isEmpty) {
      return Center(
        child: Text('No hay resultados'),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      itemCount: _resultados.length,
      itemBuilder: (BuildContext context, int index) {
        final resultado = _resultados[index];

        if (resultado.isNotEmpty) {
          return Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12, width: 3),
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              constraints: BoxConstraints(maxWidth: 300),
              margin: EdgeInsets.only(right: 16.0),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Salón: ${resultado['salon']} - Edificio: ${resultado['edificio']} \nHorario:  \n'
                      'Docente: ${resultado['docente']} \nMateria: ${resultado['materia']} \nAsistencias:',
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: resultado['asistencia'].length,
                      itemBuilder: (BuildContext context, int index) {
                        final asistenciaRegistro =
                            resultado['asistencia'][index];
                        final revisor = asistenciaRegistro['revisor'];
                        final fecha = DateFormat('dd/MM/yyyy HH:mm').format(
                          asistenciaRegistro['fecha'].toDate().toLocal(),
                        );

                        return ListTile(
                          title: Text('Revisor: $revisor \nFecha: $fecha'),
                          leading: Icon(Icons.assignment_outlined),
                        );
                      },
                    ),
                  ),
                ],
              ));
        }

        return SizedBox();
      },
    );
  }

  void _realizarConsulta() {
    setState(() {
      _resultados.clear();
    });

    if (_selectedConsulta == 'asistenciaPorDocente') {
      final docente = _docenteConsultaController.text;

      FirebaseFirestore.instance
          .collection('asignacion')
          .where('docente', isEqualTo: docente)
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _resultados.add(data);
          });
        });
      }).catchError((error) {
        print('Error al realizar la consulta: $error');
      });
    } else if (_selectedConsulta == 'asistenciaPorFechas') {
      DateTime fechaIni =
          DateFormat('dd/MM/yyyy').parse(_fechaIniConsultaController.text);
      DateTime fechaFin =
          DateFormat('dd/MM/yyyy').parse(_fechaFinConsultaController.text);
      FirebaseFirestore.instance
          .collection('asignacion')
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final asistencia = data['asistencia'] as List<dynamic>;
          final filteredAsistencia = asistencia.where((dynamic registro) {
            final fecha =
                (registro['fecha'] as Timestamp).toDate().toLocal() as DateTime;
            return fecha.isAfter(fechaIni) && fecha.isBefore(fechaFin);
          }).toList();

          if (filteredAsistencia.isNotEmpty) {
            setState(() {
              data['asistencia'] = filteredAsistencia;
              _resultados.add(data);
            });
          }
        });
      }).catchError((error) {
        print('Error al realizar la consulta: $error');
      });
    } else if (_selectedConsulta == 'asistenciaPorFechasYEdificio') {
      DateTime fechaIni =
          DateFormat('dd/MM/yyyy').parse(_fechaIniConsultaController.text);
      DateTime fechaFin =
          DateFormat('dd/MM/yyyy').parse(_fechaFinConsultaController.text);
      final edificio = _selectedEdificio;

      FirebaseFirestore.instance
          .collection('asignacion')
          .where('edificio', isEqualTo: edificio)
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final asistencia = data['asistencia'] as List<dynamic>;
          final filteredAsistencia = asistencia.where((dynamic registro) {
            final fecha =
                (registro['fecha'] as Timestamp).toDate().toLocal() as DateTime;
            return fecha.isAfter(fechaIni) && fecha.isBefore(fechaFin);
          }).toList();

          if (filteredAsistencia.isNotEmpty) {
            setState(() {
              data['asistencia'] = filteredAsistencia;
              _resultados.add(data);
            });
          }
        });
      }).catchError((error) {
        print('Error al realizar la consulta: $error');
      });
    } else if (_selectedConsulta == 'asistenciaPorRevisor') {
      final revisor2 = _revisorConsultaController.text;

      FirebaseFirestore.instance
          .collection('asignacion')
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final asistencia = data['asistencia'] as List<dynamic>;
          final filteredAsistencia = asistencia.where((dynamic registro) {
            final revisor = registro['revisor'];
            return revisor == revisor2;
          }).toList();

          if (filteredAsistencia.isNotEmpty) {
            setState(() {
              data['asistencia'] = filteredAsistencia;
              _resultados.add(data);
            });
          }
        });
      }).catchError((error) {
        print('Error al realizar la consulta: $error');
      });
    }
  }
}
