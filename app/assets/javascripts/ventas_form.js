document.addEventListener('turbo:load', () => {
  const tipoSelect = document.getElementById('filtro-tipo');
  const categoriaSelect = document.getElementById('filtro-categoria');
  const productoSelect = document.getElementById('producto-select');
  const precioInput = document.getElementById('precio-input');

  if (!productoSelect) return; // no estamos en la página de ventas

  async function cargarProductos() {
    const params = new URLSearchParams();
    if (tipoSelect && tipoSelect.value) params.append('tipo', tipoSelect.value);
    if (categoriaSelect && categoriaSelect.value) params.append('categoria', categoriaSelect.value);

    productoSelect.innerHTML = '<option value="">Cargando...</option>';

    try {
      const resp = await fetch(`/productos_filtrados?${params.toString()}`);
      if (!resp.ok) throw new Error('Error al obtener productos');
      const productos = await resp.json();

      productoSelect.innerHTML = '<option value="">Seleccioná un producto</option>';
      productos.forEach(p => {
        const opt = document.createElement('option');
        opt.value = p.id;
        opt.textContent = `${p.titulo} — $${p.precio}`;
        opt.dataset.precio = p.precio;
        productoSelect.appendChild(opt);
      });
    } catch (err) {
      productoSelect.innerHTML = '<option value="">Error al cargar</option>';
      console.error(err);
    }
  }

  if (tipoSelect) tipoSelect.addEventListener('change', cargarProductos);
  if (categoriaSelect) categoriaSelect.addEventListener('change', cargarProductos);

  productoSelect.addEventListener('change', () => {
    const opt = productoSelect.options[productoSelect.selectedIndex];
    precioInput.value = opt && opt.dataset.precio ? opt.dataset.precio : '';
  });

  // Si ya hay filtros seleccionados al cargar la página, poblar productos
  if ((tipoSelect && tipoSelect.value) || (categoriaSelect && categoriaSelect.value)) {
    cargarProductos();
  }
});
