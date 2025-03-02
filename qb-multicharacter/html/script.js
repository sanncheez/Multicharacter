let characters = [];
let currentCharacter = null;

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (!data) return;

    switch (data.action) {
        case "setupCharacters":
            if (Array.isArray(data.characters)) {
                characters = data.characters;
                loadCharacters();
            }
            break;
        case "openUI":
            if (Array.isArray(data.characters)) {
                characters = data.characters;
                loadCharacters();
            }
            $('.container').fadeIn(250);
            break;
        case "closeUI":
            $('.container').fadeOut(250);
            break;
    }
});

function loadCharacters() {
    const charactersList = $('.characters-list');
    charactersList.empty();

    characters.forEach((char, index) => {
        if (!char || !char.charinfo) return;
        
        const charInfo = char.charinfo;
        const slot = $(`
            <div class="character-slot" data-citizenid="${char.citizenid}">
                <div class="char-info-preview">
                    <h3>${charInfo.firstname} ${charInfo.lastname}</h3>
                    <p>Género: ${charInfo.gender === 'male' ? 'Hombre' : 'Mujer'}</p>
                    <p>Dinero: $${char.money?.cash || 0}</p>
                </div>
            </div>
        `);
        
        slot.click(function() {
            $('.character-slot').removeClass('selected');
            $(this).addClass('selected');
            showCharacterInfo(char);
        });
        
        charactersList.append(slot);
    });
}

// Función para mostrar la información detallada del personaje
function showCharacterInfo(char) {
    const charInfo = char.charinfo;
    $('#char-name').text(`${charInfo.firstname} ${charInfo.lastname}`);
    $('#char-gender').text(charInfo.gender === 'male' ? 'Hombre' : 'Mujer');
    $('#char-job').text(char.job?.label || 'Desempleado');
    $('#char-money').text(`$${char.money?.cash || 0}`);
    $('#char-bank').text(`$${char.money?.bank || 0}`);
    
    $('.character-info').fadeIn(300);
}

// Evento para recibir actualizaciones del servidor
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === "setupCharacters") {
        characters = data.characters || [];
        loadCharacters();
    }
});

// Modificar el manejador de eventos para los botones
$('#play-char').on('click', function() {
    const selectedChar = $('.character-slot.selected');
    if (selectedChar.length > 0) {
        const citizenid = selectedChar.data('citizenid');
        // Enviar evento al cliente
        $.post('https://qb-multicharacter/selectCharacter', JSON.stringify({
            citizenid: citizenid
        }));
        // Ocultar UI
        $('.character-info').fadeOut(300);
        $('.characters-block').fadeOut(300);
    }
});

$(document).on('click', '.delete-btn', function(e) {
    e.stopPropagation();
    const index = $(this).data('index');
    if (characters[index] && confirm('¿Estás seguro de que quieres eliminar este personaje?')) {
        $.post('https://qb-multicharacter/deleteCharacter', JSON.stringify({
            citizenid: characters[index].citizenid
        }));
    }
});

// Inicialización
$(document).ready(() => {
    // Asegurarse de que characters sea un array
    if (!Array.isArray(characters)) {
        characters = [];
    }
    loadCharacters();
});

$(document).ready(function() {
    // Manejador para el botón de crear nuevo personaje
    $('#create-new-char').on('click', function() {
        $('.character-register').fadeIn(300);
        $('.characters-block').css('filter', 'blur(2px)');
        if($('.character-info').is(':visible')) {
            $('.character-info').fadeOut(300);
        }
    });

    // Manejador para el botón de cancelar
    $('#cancel-create').on('click', function(e) {
        e.preventDefault();
        $('.character-register').fadeOut(300);
        $('.characters-block').css('filter', 'none');
        $('#char-register-form')[0].reset();
    });

    // Manejador para enviar el formulario
// Manejador para enviar el formulario de creación
$('#char-register-form').on('submit', function(e) {
    e.preventDefault();
    
    const formData = {
        firstname: $('#firstname').val().trim(),
        lastname: $('#lastname').val().trim(),
        birthdate: $('#birthdate').val(),
        gender: $('#gender').val(),
        nationality: $('#nationality').val().trim()
    };

    // Validación básica
    if (!formData.firstname || !formData.lastname || !formData.birthdate) {
        // Podrías mostrar un mensaje de error aquí
        return;
    }

    // Enviar datos al cliente
    $.post('https://qb-multicharacter/createCharacter', JSON.stringify(formData), function(response) {
        if (response === "ok") {
            // Ocultar formulario
            $('.character-register').fadeOut(300);
            $('.characters-block').css('filter', 'none');
            
            // Limpiar formulario
            $('#char-register-form')[0].reset();
            
            // Actualizar la lista de personajes después de un breve delay
            setTimeout(() => {
                loadCharacters();
            }, 1000);
        }
    });
 } );
});

// anims 

$('#animation').on('change', function() {
    const selectedAnim = $(this).val();
    $.post('https://qb-multicharacter/updatePlayerAnim', JSON.stringify({
        anim: selectedAnim
    }));
});