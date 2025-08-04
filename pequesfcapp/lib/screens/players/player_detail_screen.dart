import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class PlayerDetailScreen extends StatelessWidget {
  final PlayerModel player;

  const PlayerDetailScreen({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${player.nombres} ${player.apellido}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    AssetImage('assets/jugador.png') as ImageProvider,
              ),
            ),
            SizedBox(height: 20),
            _buildDetailItem('Nombres', player.nombres),
            _buildDetailItem('Apellido', player.apellido),
            _buildDetailItem('Fecha de Nacimiento',
                '${player.fechaDeNacimiento.toLocal().toString().split(' ')[0]}'),
            _buildDetailItem('Lugar de Nacimiento', player.lugarDeNacimiento),
            _buildDetailItem('Género', player.genero),
            _buildDetailItem(
                'Apoderado ID', player.guardianId ?? 'Sin asignar'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aquí puedes navegar a una pantalla para asignar o cambiar apoderado
                // Navigator.push(context, MaterialPageRoute(builder: (_) => AsignarApoderadoScreen(player: player)));
              },
              child: Text('Asignar o Cambiar Apoderado'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
