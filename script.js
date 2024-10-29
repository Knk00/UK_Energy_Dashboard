document.addEventListener('DOMContentLoaded', () => {
    const hamburger = document.getElementById('hamburger');
    const sidebar = document.getElementById('sidebar');

    // Toggle sidebar
    hamburger.addEventListener('click', () => {
        sidebar.style.left = sidebar.style.left === '0px' ? '-250px' : '0';
    });

    // Auto-hide sidebar on mouse leave
    sidebar.addEventListener('mouseleave', () => {
        sidebar.style.left = '-250px';
    });

    // Scroll animations
    const sections = document.querySelectorAll('.section');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('show');
            }
        });
    }, { threshold: 0.2 });

    sections.forEach(section => observer.observe(section));
});


// Define global variables to store the pre-aggregated data
let monthlyData, yearlyData;

// Load the dataset only once and pre-aggregate it
d3.csv("./Data/merged.csv").then(data => {
    const parseTime = d3.timeParse("%d/%m/%Y %H:%M");

    // Parse and clean data
    data.forEach(d => {
        d.timestamp = parseTime(d.timestamp);
        d.nd = +d.nd;
    });

    // Filter valid data points
    data = data.filter(d => d.timestamp && !isNaN(d.nd));

    // Pre-aggregate monthly data
    monthlyData = d3.rollup(data, 
        v => d3.mean(v, d => d.nd),
        d => d3.timeMonth.floor(d.timestamp)
    );

    // Pre-aggregate yearly data
    yearlyData = d3.rollup(data, 
        v => d3.mean(v, d => d.nd),
        d => d3.timeYear.floor(d.timestamp)
    );

    // Convert aggregated Maps to Arrays
    monthlyData = Array.from(monthlyData, ([key, value]) => ({ timestamp: key, nd: value }));
    yearlyData = Array.from(yearlyData, ([key, value]) => ({ timestamp: key, nd: value }));

    // Render the initial chart with monthly data
        updateChart(monthlyData);
        
    // Add event listener for the dropdown filter
    d3.select("#resolution-select").on("change", function (event) {
        const resolution = event.target.value;  // Get selected value

        // Switch between datasets based on resolution
        if (resolution === "monthly") {
            updateChart(monthlyData);  // Render monthly data
        } else if (resolution === "yearly") {
            updateChart(yearlyData);  // Render yearly data
        }
});

});


// Create the SVG container with adjusted width and height
const margin = { top: 60, right: 70, bottom: 80, left: 90 };
const width = 800 - margin.left - margin.right;
const height = 500 - margin.top - margin.bottom;

const svg = d3.select("#chart")
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);

// Add title to the chart
svg.append("text")
    .attr("x", width / 2)
    .attr("y", -20)
    .attr("text-anchor", "middle")
    .style("font-size", "24px")
    .style("font-weight", "600");
    // .text("Evolution of National Demand Over Time");

// Define scales
const x = d3.scaleTime()
    .domain([new Date(2008, 1, 1), new Date(2025, 0, 1)])  // Slightly padded range
    .range([0, width]);

const y = d3.scaleLinear()
    .range([height, 0]);

// Create axis groups
const xAxisGroup = svg.append("g")
    .attr("transform", `translate(0,${height})`);

const yAxisGroup = svg.append("g");

// Add X axis label
svg.append("text")
    .attr("x", width / 2)
    .attr("y", height + 50)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("Year");

// Add Y axis label
svg.append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", -60)
    .attr("x", -height / 2)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .text("National Demand (MW)");

// Add gridlines for better visualization
function addGridlines() {
    // X-axis gridlines
    svg.append("g")
        .attr("class", "grid")
        .attr("transform", `translate(0,${height})`)
        .call(d3.axisBottom(x).ticks(10).tickSize(-height).tickFormat(""));

    // Y-axis gridlines
    svg.append("g")
        .attr("class", "grid")
        .call(d3.axisLeft(y).ticks(5).tickSize(-width).tickFormat(""));
}

document.addEventListener("DOMContentLoaded", () => {
    const resolutionSelect = document.getElementById("resolution-select");
    resolutionSelect.value = "monthly"; // Set to yearly by default
    updateChart("monthly"); // Call the function with 'yearly'
});

// Tooltip div
const tooltip = d3.select("body").append("div")
    .attr("class", "tooltip");

// Update chart function
function updateChart(data) {
    const ndMin = d3.min(data, d => d.nd);
    const ndMax = d3.max(data, d => d.nd);
    const yPadding = 0.25 * (ndMax - ndMin); // Add 25% padding

    // Update scales with padded domains
    x.domain(d3.extent(data, d => d.timestamp));
    y.domain([ndMin - yPadding, ndMax + yPadding]);

    // Render axes with ticks and appropriate font size
    xAxisGroup.call(d3.axisBottom(x).ticks(10).tickSizeOuter(0))
        .selectAll("text")
        .style("font-size", "14px");
    
    xAxisGroup.call(
        d3.axisBottom(x)
            .ticks(d3.timeYear.every(1))  // Yearly ticks
            .tickFormat(d3.timeFormat("%Y"))  // Format as 'YYYY'
            .tickSizeOuter(0)  // No outer ticks
    )        .selectAll("text")
    .style("font-size", "14px");

    yAxisGroup.call(d3.axisLeft(y).ticks(5).tickSizeOuter(0))
        .selectAll("text")
        .style("font-size", "14px");

    // Add gridlines
    svg.selectAll(".grid").remove(); // Clear previous gridlines
    addGridlines();

    // Draw the line
    svg.selectAll(".line").remove(); // Clear previous lines
    svg.append("path")
        .datum(data)
        .attr("class", "line")
        .attr("fill", "none")
        .attr("stroke", "#1e90ff")
        .attr("stroke-width", 2)
        .attr("d", d3.line()
            .x(d => x(d.timestamp))
            .y(d => y(d.nd))
        );

    // Draw circles with tooltips
    svg.selectAll("circle").remove(); // Clear previous circles
    svg.selectAll("circle")
        .data(data)
        .enter().append("circle")
        .attr("cx", d => x(d.timestamp))
        .attr("cy", d => y(d.nd))
        .attr("r", 4)
        .attr("fill", "#1e90ff")
        .on("mouseover", (event, d) => {
            tooltip.style("visibility", "visible")
                .html(`Time: ${d3.timeFormat("%B %Y")(d.timestamp)}<br>Demand: ${Math.round(d.nd)} MW`);
        })
        .on("mousemove", event => {
            tooltip.style("top", `${event.pageY - 10}px`)
                .style("left", `${event.pageX + 10}px`);
        })
        .on("mouseout", () => tooltip.style("visibility", "hidden"));
}


document.addEventListener('DOMContentLoaded', () => {
    const margin = { top: 60, right: 70, bottom: 80, left: 90 };
    const width = 500 - margin.left - margin.right;
    const height = 400 - margin.top - margin.bottom;

    // SVG setup for stream graph
    const svgStream = d3.select('#stream-graph')
        .append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
        .attr('transform', `translate(${margin.left},${margin.top})`);

    const x = d3.scaleTime().range([0, width]);
    const y = d3.scaleLinear().range([height, 0]);

    const tooltip = d3.select('body').append('div')
        .attr('class', 'tooltip')
        .style('visibility', 'hidden');

    const line = svgStream.append('line')
        .attr('stroke', 'red')
        .attr('stroke-width', 2)
        .attr('y1', 0)
        .attr('y2', height)
        .style('visibility', 'hidden');

    // SVG setup for sunburst chart
    const svgSunburst = d3.select('#sunburst-chart')
        .append('svg')
        .attr('width', width)
        .attr('height', height)
        .append('g')
        .attr('transform', `translate(${width / 2},${height / 2})`);

    const radius = Math.min(width, height) / 2;
    const partition = d3.partition().size([2 * Math.PI, radius]);

    const arc = d3.arc()
        .startAngle(d => d.x0)
        .endAngle(d => d.x1)
        .innerRadius(d => d.y0)
        .outerRadius(d => d.y1);

    d3.csv("./Data/merged.csv").then(data => {
        const parseTime = d3.timeParse("%d/%m/%Y %H:%M");

        data.forEach(d => {
            d.timestamp = parseTime(d.timestamp);
            d.nd = +d.nd;
        });

        const monthlyData = d3.rollup(data,
            v => d3.mean(v, d => d.nd),
            d => d3.timeMonth.floor(d.timestamp)
        );

        const yearlyData = d3.rollup(data,
            v => d3.mean(v, d => d.nd),
            d => d3.timeYear.floor(d.timestamp)
        );

        function updateStreamGraph(data) {
            x.domain(d3.extent(data, d => d.timestamp));
            y.domain([0, d3.max(data, d => d.nd)]);

            svgStream.selectAll('.stream-line').remove();
            svgStream.append('path')
                .datum(data)
                .attr('class', 'stream-line')
                .attr('fill', 'none')
                .attr('stroke', '#1e90ff')
                .attr('stroke-width', 2)
                .attr('d', d3.line()
                    .x(d => x(d.timestamp))
                    .y(d => y(d.nd))
                );

            svgStream.selectAll('circle').remove();
            svgStream.selectAll('circle')
                .data(data)
                .enter().append('circle')
                .attr('cx', d => x(d.timestamp))
                .attr('cy', d => y(d.nd))
                .attr('r', 4)
                .attr('fill', '#1e90ff')
                .on('mouseover', (event, d) => {
                    line.attr('x1', x(d.timestamp)).attr('x2', x(d.timestamp))
                        .style('visibility', 'visible');
                    tooltip.style('visibility', 'visible')
                        .html(`Year: ${d3.timeFormat('%Y')(d.timestamp)}<br>Demand: ${Math.round(d.nd)} MW`);
                    updateSunburst(d);
                })
                .on('mousemove', event => {
                    tooltip.style('top', `${event.pageY - 10}px`)
                        .style('left', `${event.pageX + 10}px`);
                })
                .on('mouseout', () => {
                    line.style('visibility', 'hidden');
                    tooltip.style('visibility', 'hidden');
                });
        }

        function updateSunburst(d) {
            const data = {
                name: 'Energy',
                children: [
                    { name: 'Coal', value: d.nd * 0.3 },
                    { name: 'Gas', value: d.nd * 0.5 },
                    { name: 'Wind', value: d.nd * 0.2 }
                ]
            };

            const root = d3.hierarchy(data).sum(d => d.value);
            svgSunburst.selectAll('path').remove();
            partition(root);

            svgSunburst.selectAll('path')
                .data(root.descendants())
                .enter().append('path')
                .attr('d', arc)
                .attr('fill', d => d.depth === 1 ? '#1e90ff' : '#87ceeb');
        }

        updateStreamGraph(Array.from(yearlyData, ([key, value]) => ({ timestamp: key, nd: value })));
    });
});
