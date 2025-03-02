# qb-multicharacter

Este proyecto es un sistema de multicharacter para juegos, diseñado para ofrecer una experiencia moderna y atractiva a los jugadores. A continuación se presentan las instrucciones de configuración y uso.

## Estructura del Proyecto

- **client/**: Contiene la lógica del lado del cliente.
  - **main.lua**: Punto de entrada para la lógica del cliente.
  - **interface.lua**: Maneja la interfaz de usuario del sistema multicharacter.

- **server/**: Contiene la lógica del lado del servidor.
  - **main.lua**: Maneja los datos de los personajes y las interacciones con la base de datos.

- **html/**: Contiene los archivos para la interfaz de usuario.
  - **index.html**: Estructura principal del HTML.
  - **style.css**: Estilos para la interfaz HTML.
  - **script.js**: Lógica JavaScript para la interfaz HTML.

- **locales/**: Contiene archivos de localización.
  - **es.lua**: Cadenas de localización para el idioma español.

- **config.lua**: Configuraciones del sistema multicharacter.

- **fxmanifest.lua**: Manifiesto del recurso, define metadatos y dependencias.

## Instalación

1. Clona este repositorio en tu servidor.
2. Asegúrate de tener todas las dependencias necesarias instaladas.
3. Configura los detalles de conexión a la base de datos en `config.lua`.
4. Inicia el recurso en tu servidor.

## Uso

Los jugadores pueden interactuar con el sistema de multicharacter a través de la interfaz de usuario, donde podrán crear, seleccionar y gestionar sus personajes. 

## Contribuciones

Las contribuciones son bienvenidas. Si deseas contribuir, por favor abre un issue o un pull request.

## Licencia

Este proyecto está bajo la Licencia MIT.