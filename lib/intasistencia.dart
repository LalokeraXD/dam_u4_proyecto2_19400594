import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';

class IntAsistencia extends StatefulWidget {
  const IntAsistencia({Key? key}) : super(key: key);

  @override
  State<IntAsistencia> createState() => _IntAsistenciaState();
}

class _IntAsistenciaState extends State<IntAsistencia> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _asistenciasStream;

  String? _selectedSalon;
  String? _selectedEdificio;

  String fechaFormateada = "";

  bool hayAsistencias = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _salonController = TextEditingController();
  final TextEditingController _edificioController = TextEditingController();
  final TextEditingController _horarioController = TextEditingController();
  final TextEditingController _docenteController = TextEditingController();
  final TextEditingController _materiaController = TextEditingController();
  final TextEditingController _revisorController = TextEditingController();
  final TextEditingController _fecHoraController = TextEditingController();

  TimeOfDay selectedHora = TimeOfDay.now();

  Future<void> _selectHora(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedHora,
    );

    if (pickedTime != null && pickedTime != selectedHora) {
      setState(() {
        selectedHora = pickedTime;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _asistenciasStream = _firestore.collection('asignacion').snapshots();
  }

  @override
  void dispose() {
    _salonController.dispose();
    _edificioController.dispose();
    _horarioController.dispose();
    _docenteController.dispose();
    _materiaController.dispose();
    _revisorController.dispose();
    _fecHoraController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de Asistencias',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 55,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: hayAsistencias
            ? _buildAgregarAsistenciaForm()
            : _buildListaAsistencias(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            hayAsistencias = !hayAsistencias;
          });
        },
        child: Icon(hayAsistencias ? Icons.cancel : Icons.add),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildListaAsistencias() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _asistenciasStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final asistencias = snapshot.data!.docs;
          return ListView.builder(
            itemCount: asistencias.length,
            itemBuilder: (context, index) {
              final asistenciaData = asistencias[index].data();
              final salon = asistenciaData['salon'];
              final edificio = asistenciaData['edificio'];
              final horario = asistenciaData['horario'];
              final docente = asistenciaData['docente'];
              return ListTile(
                title: Text('Docente: $docente'),
                subtitle: Text(
                    'Horario: $horario \nSalón: $salon - Edificio: $edificio'),
                leading: Icon(Icons.assignment_outlined),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'detalles',
                      child: Text('Detalles'),
                    ),
                    PopupMenuItem(
                      value: 'actualizar',
                      child: Text('Actualizar campos'),
                    ),
                    PopupMenuItem(
                      value: 'registrar',
                      child: Text('Registrar asistencia'),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Text('Eliminar Reporte'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'detalles') {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Detalles del reporte'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Salon: ${asistenciaData['salon']}',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    'Edificio: ${asistenciaData['edificio']}',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    'Horario: ${asistenciaData['horario']}',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    'Docente: ${asistenciaData['docente']}',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    'Materia: ${asistenciaData['materia']}',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Asistencia:',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  SizedBox(
                                    height: 100,
                                    width: 300,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          asistenciaData['asistencia'].length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final asistenciaRegistro =
                                            asistenciaData['asistencia'][index];
                                        final revisor =
                                            asistenciaRegistro['revisor'];
                                        final fecha =
                                            DateFormat('dd/MM/yyyy HH:mm')
                                                .format(
                                                    asistenciaRegistro['fecha']
                                                        .toDate()
                                                        .toLocal());

                                        return ListTile(
                                          title: Text('Revisor: $revisor'),
                                          subtitle: Text('Fecha: $fecha'),
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('Cerrar'),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (value == 'eliminar') {
                      _eliminarAsistencia(asistencias[index].reference);
                    } else if (value == 'actualizar') {
                      _mostrarActualizarCamposDialog(asistencias[index]);
                    } else if (value == 'registrar') {
                      _registrarAsistencia(asistencias[index]);
                    }
                  },
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  Widget _buildAgregarAsistenciaForm() {
    return SingleChildScrollView(
        child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _selectedSalon,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSalon = newValue;
                });
                if (_selectedSalon == 'A1' ||
                    _selectedSalon == 'A2' ||
                    _selectedSalon == 'A3') {
                  setState(() {
                    _selectedEdificio = 'A';
                  });
                } else if (_selectedSalon == 'X1' ||
                    _selectedSalon == 'X2' ||
                    _selectedSalon == 'X3') {
                  setState(() {
                    _selectedEdificio = 'X';
                  });
                } else if (_selectedSalon == 'UD1' || _selectedSalon == 'UD2') {
                  setState(() {
                    _selectedEdificio = 'UD';
                  });
                }
              },
              items: [
                DropdownMenuItem<String>(
                  value: 'A1',
                  child: Text('A1'),
                ),
                DropdownMenuItem<String>(
                  value: 'A2',
                  child: Text('A2'),
                ),
                DropdownMenuItem<String>(
                  value: 'A3',
                  child: Text('A3'),
                ),
                DropdownMenuItem<String>(
                  value: 'X1',
                  child: Text('X1'),
                ),
                DropdownMenuItem<String>(
                  value: 'X2',
                  child: Text('X2'),
                ),
                DropdownMenuItem<String>(
                  value: 'UD1',
                  child: Text('UD1'),
                ),
                DropdownMenuItem<String>(
                  value: 'UD2',
                  child: Text('UD2'),
                ),
              ],
              decoration: InputDecoration(
                labelText: 'Salón',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor selecciona el salón';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedEdificio,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedEdificio = newValue;
                });

                if (_selectedEdificio == 'A' &&
                    !(_selectedSalon == 'A1' ||
                        _selectedSalon == 'A2' ||
                        _selectedSalon == 'A3')) {
                  setState(() {
                    _selectedSalon = 'A1';
                  });
                } else if (_selectedEdificio == 'X' &&
                    !(_selectedSalon == 'X1' ||
                        _selectedSalon == 'X2' ||
                        _selectedSalon == 'X3')) {
                  setState(() {
                    _selectedSalon = 'X1';
                  });
                } else if (_selectedEdificio == 'UD' &&
                    !(_selectedSalon == 'UD1' || _selectedSalon == 'UD2')) {
                  setState(() {
                    _selectedSalon = 'UD1';
                  });
                }
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
                  return 'Por favor selecciona el Edificio';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  selectedHora.format(context),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _selectHora(context),
                  child: Text('Seleccionar horario'),
                ),
              ],
            ),
            TextFormField(
              controller: _docenteController,
              decoration: InputDecoration(
                labelText: 'Docente',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre del docente';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _materiaController,
              decoration: InputDecoration(
                labelText: 'Materia',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre de la materia';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final salon = _selectedSalon;
                  final edificio = _selectedEdificio;
                  final horario = DateFormat.Hm().format(
                    DateTime(0, 0, 0, selectedHora.hour, selectedHora.minute),
                  );
                  final docente = _docenteController.text;
                  final materia = _materiaController.text;

                  _firestore.collection('asignacion').add({
                    'salon': salon,
                    'edificio': edificio,
                    'horario': horario.toString(),
                    'docente': docente,
                    'materia': materia,
                    'asistencia': [],
                  }).then((value) {
                    _selectedSalon = '';
                    _selectedEdificio = '';
                    selectedHora = TimeOfDay.now();
                    _docenteController.clear();
                    _materiaController.clear();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reporte agregado correctamente')),
                    );
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al agregar el reporte')),
                    );
                  });
                }
              },
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    ));
  }

  void _mostrarActualizarCamposDialog(DocumentSnapshot asistencia) {
    final salon = asistencia['salon'];
    final edificio = asistencia['edificio'];
    final docente = asistencia['docente'];
    final materia = asistencia['materia'];

    _selectedSalon = salon;
    _selectedEdificio = edificio;

    selectedHora =
        TimeOfDay(hour: selectedHora.hour, minute: selectedHora.minute);

    showDialog(
      context: context,
      builder: (context) {
        TextEditingController docenteController =
            TextEditingController(text: docente);
        TextEditingController materiaController =
            TextEditingController(text: materia);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Actualizar campos del reporte'),
              content: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          value: _selectedSalon,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSalon = newValue;
                              if (_selectedSalon == 'A1' ||
                                  _selectedSalon == 'A2' ||
                                  _selectedSalon == 'A3') {
                                _selectedEdificio = 'A';
                              } else if (_selectedSalon == 'X1' ||
                                  _selectedSalon == 'X2' ||
                                  _selectedSalon == 'X3') {
                                _selectedEdificio = 'X';
                              } else if (_selectedSalon == 'UD1' ||
                                  _selectedSalon == 'UD2' ||
                                  _selectedSalon == 'UD3') {
                                _selectedEdificio = 'UD';
                              }
                            });
                          },
                          items: [
                            DropdownMenuItem<String>(
                              value: 'A1',
                              child: Text('A1'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'A2',
                              child: Text('A2'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'A3',
                              child: Text('A3'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'X1',
                              child: Text('X1'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'X2',
                              child: Text('X2'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'X3',
                              child: Text('X3'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'UD1',
                              child: Text('UD1'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'UD2',
                              child: Text('UD2'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Salón',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor selecciona el salón';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedEdificio,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedEdificio = newValue;
                              if (_selectedEdificio == 'A' &&
                                  !(_selectedSalon == 'A1' ||
                                      _selectedSalon == 'A2' ||
                                      _selectedSalon == 'A3')) {
                                _selectedSalon = 'A1';
                              } else if (_selectedEdificio == 'X' &&
                                  !(_selectedSalon == 'X1' ||
                                      _selectedSalon == 'X2' ||
                                      _selectedSalon == 'X3')) {
                                _selectedSalon = 'X1';
                              } else if (_selectedEdificio == 'UD' &&
                                  !(_selectedSalon == 'UD1' ||
                                      _selectedSalon == 'UD2' ||
                                      _selectedSalon == 'UD3')) {
                                _selectedSalon = 'UD1';
                              }
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
                              return 'Por favor selecciona el Edificio';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              selectedHora.format(context),
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () => _selectHora(context),
                              child: Text('Seleccionar horario'),
                            ),
                          ],
                        ),
                        TextFormField(
                          controller: docenteController,
                          decoration: InputDecoration(
                            labelText: 'Docente',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el nombre del docente';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: materiaController,
                          decoration: InputDecoration(
                            labelText: 'Materia',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el nombre de la materia';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                        context); // Cerrar el diálogo sin hacer cambios
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      asistencia.reference.update({
                        'salon': _selectedSalon,
                        'edificio': _selectedEdificio,
                        'horario':
                            '${selectedHora.hour}:${selectedHora.minute.toString().padLeft(2, '0')}',
                        'docente': docenteController.text,
                        'materia': materiaController.text,
                      }).then((value) {
                        Navigator.pop(
                            context); // Cerrar el diálogo después de la actualización
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Campos actualizados correctamente')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error al actualizar los campos')),
                        );
                      });
                    }
                  },
                  child: Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _registrarAsistencia(DocumentSnapshot asistencia) {
    final asistenciaId = asistencia.id;
    final DateTime now = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String revisor = '';

        return AlertDialog(
          title: Text('Registrar asistencia'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Salon: ${asistencia['salon']}',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Edificio: ${asistencia['edificio']}',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Horario: ${asistencia['horario']}',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Docente: ${asistencia['docente']}',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Materia: ${asistencia['materia']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 16),
                Text(
                  'Revisor:',
                  style: TextStyle(fontSize: 18),
                ),
                TextField(
                  onChanged: (value) {
                    revisor = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if(revisor.replaceAll(" ", "").isEmpty){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('El campo no puede estar vacío.')),
                  );
                  return;
                }

                final Map<String, dynamic> asistenciaData = {
                  'revisor': revisor,
                  'fecha': now,
                };

                List<Map<String, dynamic>> existingAsistencia =
                    List<Map<String, dynamic>>.from(
                        asistencia['asistencia'] ?? []);
                existingAsistencia.add(asistenciaData);

                _firestore.collection('asignacion').doc(asistencia.id).update({
                  'asistencia': existingAsistencia,
                }).then((value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Asistencia registrada correctamente')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al registrar la asistencia')),
                  );
                });
                Navigator.pop(context);
              },
              child: Text('Registrar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarAsistencia(DocumentReference reference) {
    reference.delete().then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte eliminado correctamente')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el reporte')),
      );
    });
  }
}
