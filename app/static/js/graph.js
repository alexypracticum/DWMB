/**
 * D3.js Force-Directed Graph for DWMB entity relations.
 */
function initGraph(containerId, data, options = {}) {
    const container = document.getElementById(containerId);
    if (!container || !data || !data.nodes || data.nodes.length === 0) return;

    const width = container.clientWidth;
    const height = options.height || 500;
    const centerId = data.nodes.find(n => n.is_center)?.id;

    // Clear previous
    container.innerHTML = '';

    const svg = d3.select(container)
        .append('svg')
        .attr('width', width)
        .attr('height', height)
        .attr('viewBox', [0, 0, width, height]);

    // Zoom
    const g = svg.append('g');
    const zoom = d3.zoom()
        .scaleExtent([0.3, 4])
        .on('zoom', (event) => g.attr('transform', event.transform));
    svg.call(zoom);

    // Single edge color
    const edgeColor = '#94a3b8';
    const edgeHighlight = '#3b82f6';

    // Defs: arrow marker
    const defs = svg.append('defs');
    defs.append('marker')
        .attr('id', 'arrow')
        .attr('viewBox', '0 -5 10 10')
        .attr('refX', 28)
        .attr('refY', 0)
        .attr('markerWidth', 6)
        .attr('markerHeight', 6)
        .attr('orient', 'auto')
        .append('path')
        .attr('d', 'M0,-5L10,0L0,5')
        .attr('fill', edgeColor);

    defs.append('marker')
        .attr('id', 'arrow-highlight')
        .attr('viewBox', '0 -5 10 10')
        .attr('refX', 28)
        .attr('refY', 0)
        .attr('markerWidth', 6)
        .attr('markerHeight', 6)
        .attr('orient', 'auto')
        .append('path')
        .attr('d', 'M0,-5L10,0L0,5')
        .attr('fill', edgeHighlight);

    // Color scale by kind (subdued palette)
    const kinds = [...new Set(data.nodes.map(n => n.kind))];
    const kindColorScale = d3.scaleOrdinal()
        .domain(kinds)
        .range(['#6366f1', '#14b8a6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#0ea5e9', '#22c55e']);

    // Simulation
    const simulation = d3.forceSimulation(data.nodes)
        .force('link', d3.forceLink(data.edges).id(d => d.id).distance(120))
        .force('charge', d3.forceManyBody().strength(-300))
        .force('center', d3.forceCenter(width / 2, height / 2))
        .force('collision', d3.forceCollide().radius(40));

    // Edges — single color
    const link = g.append('g')
        .selectAll('line')
        .data(data.edges)
        .join('line')
        .attr('stroke', edgeColor)
        .attr('stroke-width', 1.5)
        .attr('marker-end', 'url(#arrow)');

    // Edge labels
    const linkLabel = g.append('g')
        .selectAll('text')
        .data(data.edges)
        .join('text')
        .attr('font-size', '10px')
        .attr('fill', '#94a3b8')
        .attr('text-anchor', 'middle')
        .attr('dy', -4)
        .text(d => d.relation_name);

    // Nodes
    const node = g.append('g')
        .selectAll('g')
        .data(data.nodes)
        .join('g')
        .attr('cursor', 'pointer')
        .call(d3.drag()
            .on('start', dragstarted)
            .on('drag', dragged)
            .on('end', dragended));

    // Node circles
    node.append('circle')
        .attr('r', d => d.is_center ? 22 : 16)
        .attr('fill', d => d.is_center ? '#2563eb' : kindColorScale(d.kind))
        .attr('stroke', d => d.is_center ? '#1d4ed8' : '#fff')
        .attr('stroke-width', d => d.is_center ? 3 : 2);

    // Node labels — adapt to dark mode
    const isDark = document.documentElement.classList.contains('dark');
    const labelColor = isDark ? '#e2e8f0' : '#374151';

    node.append('text')
        .attr('dy', d => d.is_center ? 36 : 30)
        .attr('text-anchor', 'middle')
        .attr('font-size', '11px')
        .attr('font-weight', d => d.is_center ? 'bold' : 'normal')
        .attr('fill', labelColor)
        .text(d => d.label.length > 20 ? d.label.substring(0, 18) + '...' : d.label);

    // Center node icon
    node.filter(d => d.is_center)
        .append('text')
        .attr('text-anchor', 'middle')
        .attr('dy', 5)
        .attr('font-size', '16px')
        .attr('fill', '#fff')
        .text('\u2605');

    // Kind badge
    node.filter(d => !d.is_center)
        .append('text')
        .attr('text-anchor', 'middle')
        .attr('dy', 4)
        .attr('font-size', '10px')
        .attr('fill', '#fff')
        .text(d => d.kind_label.charAt(0).toUpperCase());

    // Click handler
    node.on('click', (event, d) => {
        if (d.is_center) return;
        window.location.href = '/entity/' + d.id;
    });

    // Hover effects
    node.on('mouseover', function(event, d) {
        d3.select(this).select('circle')
            .transition().duration(200)
            .attr('r', d.is_center ? 26 : 20);

        // Highlight connected edges
        link.transition().duration(200)
            .attr('stroke', l => (l.source.id === d.id || l.target.id === d.id) ? edgeHighlight : '#e2e8f0')
            .attr('stroke-width', l => (l.source.id === d.id || l.target.id === d.id) ? 2.5 : 1)
            .attr('marker-end', l => (l.source.id === d.id || l.target.id === d.id) ? 'url(#arrow-highlight)' : 'url(#arrow)');

        linkLabel.transition().duration(200)
            .attr('fill', l => (l.source.id === d.id || l.target.id === d.id) ? edgeHighlight : '#cbd5e1');

        // Dim other nodes
        node.transition().duration(200)
            .attr('opacity', n => {
                if (n.id === d.id) return 1;
                const connected = data.edges.some(e =>
                    (e.source.id === d.id && e.target.id === n.id) ||
                    (e.target.id === d.id && e.source.id === n.id)
                );
                return connected ? 1 : 0.3;
            });
    });

    node.on('mouseout', function() {
        node.transition().duration(200).attr('opacity', 1);
        link.transition().duration(200)
            .attr('stroke', edgeColor)
            .attr('stroke-width', 1.5)
            .attr('marker-end', 'url(#arrow)');
        linkLabel.transition().duration(200)
            .attr('fill', '#94a3b8');
        node.select('circle')
            .transition().duration(200)
            .attr('r', d => d.is_center ? 22 : 16);
    });

    // Tick
    simulation.on('tick', () => {
        link
            .attr('x1', d => d.source.x)
            .attr('y1', d => d.source.y)
            .attr('x2', d => d.target.x)
            .attr('y2', d => d.target.y);

        linkLabel
            .attr('x', d => (d.source.x + d.target.x) / 2)
            .attr('y', d => (d.source.y + d.target.y) / 2);

        node.attr('transform', d => `translate(${d.x},${d.y})`);
    });

    // Drag functions
    function dragstarted(event, d) {
        if (!event.active) simulation.alphaTarget(0.3).restart();
        d.fx = d.x;
        d.fy = d.y;
    }

    function dragged(event, d) {
        d.fx = event.x;
        d.fy = event.y;
    }

    function dragended(event, d) {
        if (!event.active) simulation.alphaTarget(0);
        d.fx = null;
        d.fy = null;
    }

    // Filter function
    window.filterGraph = function() {
        const checked = [...document.querySelectorAll('#graph-filters input:checked')]
            .map(cb => cb.dataset.relationType);

        link.transition().duration(300)
            .attr('opacity', d => checked.length === 0 || checked.includes(d.relation_type) ? 1 : 0.05)
            .attr('stroke-width', d => checked.includes(d.relation_type) ? 2 : 1);

        linkLabel.transition().duration(300)
            .attr('opacity', d => checked.length === 0 || checked.includes(d.relation_type) ? 1 : 0);

        // Show/hide nodes that have no visible edges
        if (checked.length > 0) {
            const connectedIds = new Set();
            data.edges.forEach(e => {
                if (checked.includes(e.relation_type)) {
                    connectedIds.add(e.source.id || e.source);
                    connectedIds.add(e.target.id || e.target);
                }
            });
            connectedIds.add(centerId);

            node.transition().duration(300)
                .attr('opacity', d => connectedIds.has(d.id) ? 1 : 0.1);
        } else {
            node.transition().duration(300).attr('opacity', 1);
        }
    };

    // Expose kind colors for filter badges
    window._graphKindColors = {};
    kinds.forEach(k => window._graphKindColors[k] = kindColorScale(k));

    // Store graph data for export
    window._graphData = data;
    window._graphSvg = svg;

    // Auto-fit after simulation settles
    simulation.on('end', () => {
        const bounds = g.node().getBBox();
        const fullWidth = bounds.width + 80;
        const fullHeight = bounds.height + 80;
        const midX = bounds.x + bounds.width / 2;
        const midY = bounds.y + bounds.height / 2;
        const scale = Math.min(width / fullWidth, height / fullHeight, 1.5);
        const translate = [width / 2 - scale * midX, height / 2 - scale * midY];

        svg.transition().duration(750).call(
            zoom.transform,
            d3.zoomIdentity.translate(translate[0], translate[1]).scale(scale)
        );
    });
}

// ─── Graph Export Functions ─────────────────────────────────────

function _downloadBlob(blob, filename) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

function _getGraphFileName(ext) {
    const center = window._graphData?.nodes?.find(n => n.is_center);
    const name = center ? center.label.replace(/[^a-zA-Z0-9а-яА-ЯёЁ]/g, '_').substring(0, 30) : 'graph';
    return `graph_${name}.${ext}`;
}

/**
 * Export graph as JSON (nodes + edges + metadata)
 */
function exportGraphJSON() {
    const data = window._graphData;
    if (!data) return;

    const exportData = {
        exported_at: new Date().toISOString(),
        center: data.nodes.find(n => n.is_center)?.label || '',
        nodes: data.nodes.map(n => ({
            id: n.id,
            code: n.code,
            label: n.label,
            kind: n.kind,
            kind_label: n.kind_label,
            image_url: n.image_url,
            is_center: n.is_center,
        })),
        edges: data.edges.map(e => ({
            source: typeof e.source === 'object' ? e.source.id : e.source,
            target: typeof e.target === 'object' ? e.target.id : e.target,
            relation_type: e.relation_type,
            relation_name: e.relation_name,
            weight: e.weight,
        })),
        relation_types: data.relation_types || [],
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    _downloadBlob(blob, _getGraphFileName('json'));
    _showToast('JSON экспорт готов', 'success');
}

/**
 * Export graph as SVG
 */
function exportGraphSVG() {
    const svgEl = document.querySelector('#entity-graph svg');
    if (!svgEl) return;

    const clone = svgEl.cloneNode(true);

    // Inline computed styles for portability
    clone.querySelectorAll('text').forEach(el => {
        const computed = window.getComputedStyle(el);
        el.style.fontFamily = computed.fontFamily;
        el.style.fontSize = computed.fontSize;
    });

    // Add white background
    const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    bg.setAttribute('width', '100%');
    bg.setAttribute('height', '100%');
    bg.setAttribute('fill', '#ffffff');
    clone.insertBefore(bg, clone.firstChild);

    const serializer = new XMLSerializer();
    const svgStr = serializer.serializeToString(clone);
    const blob = new Blob([svgStr], { type: 'image/svg+xml;charset=utf-8' });
    _downloadBlob(blob, _getGraphFileName('svg'));
    _showToast('SVG экспорт готов', 'success');
}

/**
 * Export graph as PNG (rasterized from SVG)
 */
function exportGraphPNG() {
    const svgEl = document.querySelector('#entity-graph svg');
    if (!svgEl) return;

    const scale = 2; // Retina quality
    const width = svgEl.clientWidth || 1200;
    const height = svgEl.clientHeight || 500;

    const clone = svgEl.cloneNode(true);
    clone.setAttribute('width', width);
    clone.setAttribute('height', height);

    // Add white background
    const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    bg.setAttribute('width', '100%');
    bg.setAttribute('height', '100%');
    bg.setAttribute('fill', '#ffffff');
    clone.insertBefore(bg, clone.firstChild);

    const serializer = new XMLSerializer();
    const svgStr = serializer.serializeToString(clone);
    const svgBlob = new Blob([svgStr], { type: 'image/svg+xml;charset=utf-8' });
    const url = URL.createObjectURL(svgBlob);

    const img = new Image();
    img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = width * scale;
        canvas.height = height * scale;
        const ctx = canvas.getContext('2d');
        ctx.scale(scale, scale);
        ctx.drawImage(img, 0, 0, width, height);
        URL.revokeObjectURL(url);

        canvas.toBlob(blob => {
            _downloadBlob(blob, _getGraphFileName('png'));
            _showToast('PNG экспорт готов', 'success');
        }, 'image/png');
    };
    img.src = url;
}

// ─── Toast Notifications ───────────────────────────────────────

function _showToast(message, type = 'info') {
    const existing = document.getElementById('dwmb-toast');
    if (existing) existing.remove();

    const colors = {
        success: { bg: '#10b981', text: '#fff' },
        error: { bg: '#ef4444', text: '#fff' },
        info: { bg: '#3b82f6', text: '#fff' },
    };
    const c = colors[type] || colors.info;

    const toast = document.createElement('div');
    toast.id = 'dwmb-toast';
    toast.textContent = message;
    toast.style.cssText = `
        position: fixed; bottom: 24px; right: 24px; z-index: 9999;
        padding: 12px 24px; border-radius: 8px; font-size: 14px; font-weight: 500;
        background: ${c.bg}; color: ${c.text}; box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        animation: toastIn 0.3s ease;
    `;
    document.body.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transition = 'opacity 0.3s';
        setTimeout(() => toast.remove(), 300);
    }, 2500);
}

// Expose toast globally
window.showToast = _showToast;
