class GraphDisplay

    @description =
        "GraphDisplay provides display functionality to " +
        "widgets that might not need to use graph data structures."

    @spec =
        container:
            type: ["String", "jQuery Selector"]
            description:
                "The id or a jQuery selector of the div in which this widget " +
                "should draw itself."
        vertexLabels:
            type: "Object"
            defaultValue: {}
            description:
                "an object containing a mapping of label positions " +
                "(inner, nw, sw, ne, se) to labels. Labels can display " +
                "simple variable names (corresponding to inputVars). " +
                "This must be provided in the form: `{ label: ['var1', 'var2'] }`. " +
                "It can be more complicated, as a function that takes " +
                "a vertex and returns some html. if we give a label " +
                "an object, we can control what is shown in edit/display " +
                "mode in the form: " +
                "`{ label : { edit: function{}, display: function{} } }`"
            example: """
                vertexLabels: {
                    inner : {
                        edit: function(vtx){return vtx.name},
                        display: function(vtx){return vtx.d}
                    },
                    sw    : function(vtx){return vtx.name},
                    ne    : ['u', 'v'],
                    nw    : ['s'],
                }
                """
        edgeLabel:
            type: ["String", "Function","Object"]
            defaultValue: undefined
            description:
                "a string, containing the name of the edge attribute to display" +
                "or a function taking an edge and returning a string to display. " +
                "one can also specify whether to show certain things in edit or " +
                "display mode by using an object."
            example: """
                edgeLabel: { display: 'w', edit: function(e){ return e.w } },
                edgeLabel: 'w',
                edgeLabel: function(e){ return e.w + "!" },
                """

        vertexCssAttributes:
            type: "Object"
            defaultValue: {}
            description:
                "provides a way to change CSS classes of vertices based on " +
                "vertex attributes. takes an object of the form `{ attribute: " +
                "value | [list of values] }`. in the case of a single value,  " +
                "the vertex will simply get a class with the same name as " +
                "the attribute. in the case of a list of values, the css " +
                "class will be of the form 'attribute-value' when its value " +
                "matches. You can also provide a function that takes a vertex " +
                "and returns a class to apply to it."
            example: """
                vertexCssAttributes: {
                    done: true,
                    color: ['white', 'gray', 'black'],
                    magic: function(vtx){ return "class-" + vtx.magicAttr },
                },
                """

        edgeCssAttributes:
            type: "Object"
            defaultValue: undefined
            description: "provides a way to change CSS classes of edges based " +
                "upon the values of variables or the edges themselves. You provide " +
                "a mapping of classnames to functions or strings. The function " +
                "simply needs to take an edge and return a boolean (whether to " +
                "apply the class). The string is a pairing of variable names in " +
                "the form `'u->v'` or `'u<->v'` for undirected graphs."
            example: """
                edgeCssAttributes: {
                    green: function(edge){
                        return (edge.target.pred === edge.source.name)
                            || (edge.source.pred === edge.target.name)
                    },
                    red: "u->v",
                }
                """

        styleEdges:
            type: "Array"
            defaultValue: undefined
            description: "Provides a way to add styles to path objects. " +
                "Functions must return an array whose first element is an " +
                "attribute name, and second element is the value."
            example: """
                styleEdges: [
                    function(e){
                        if (e.f !== undefined && (e.f > 0)) {
                            var width = 2 + e.f;
                            return ["stroke-width", width];
                        }
                    },
                ],
                """

        containerMargin:
            type: "Number"
            defaultValue: 30
            description: "how close vertices can get to the container edge"
        minX:
            type: "Number"
            defaultValue: 100
            description: "minimum width of the graph widget"
        minY:
            type: "Number"
            defaultValue: 100
            description: "minimum height of the graph widget"
        resizable:
            type: "Boolean"
            defaultValue: true
            description: "whether the graph widget is resizable"
        draggable:
            type: "Boolean"
            defaultValue: true
            description: "whether vertices can be moved"
        highlightChanges:
            type: "Boolean"
            defaultValue: true
            description: "whether vertices will get the css class 'changed' when they are modified"
        vertexWidth:
            type: "Number"
            defaultValue: 40
            description: "the width of vertices in the graph"
        vertexHeight:
            type: "Number"
            defaultValue: 30
            description: "the height of vertices in the graph"

        arrowWidth:
            type: "Number"
            defaultValue: 6
            description: "the width of arrows in directed graphs"
        arrowLength:
            type: "Number"
            defaultValue: 6
            description: "the length of arrows in directed graphs"

        bezierCurviness:
            type: "Number"
            defaultValue: 15
            description: "the curviness of bezier curves in this graph"

        persistentDragging:
            type: "Boolean"
            defaultValue: true
            description: "whether the positions resulting from dragging " +
                "vertices are persistent across frames in display mode."

    constructor: (args) ->

        Vamonos.handleArguments
            widgetObject : this
            givenArgs    : args

        @$outer = Vamonos.jqueryify(@container)

        if @edgeLabel?.constructor.name isnt 'Object'
            @edgeLabel = { edit: @edgeLabel, display: @edgeLabel }

        @$outer.disableSelection()

        if @resizable
            @$outer.resizable
                handles: "se"
                minWidth: @minX
                minHeight: @minY

        @svg = d3.selectAll("#" + @$outer.attr("id")).append("svg")
            .attr("width", "100%")
            .attr("height", "100%")
        @inner = @initialize(@svg)

    initialize: () ->
        if @persistentDragging
            # _savex and _savey are for saving the dragged positions of
            # vertices across frames.
            @_savex = {}
            @_savey = {}
        @svg.append("g")
            .attr("transform", "translate(" +
                [ @containerMargin ,
                  @containerMargin ] + ")")

    # ------------ PUBLIC INTERACTION METHODS ------------- #

    # A widget that uses GraphDisplay will need to pass along the setup event
    # in order to register vars from vertexLabels and edgeCssAttributes
    event: (event, options...) -> switch event
        when "setup"
            [@viz, done] = options
            for klass, test of @edgeCssAttributes when typeof test is 'string'
                @viz.registerVariable(v) for v in test.split(/<?->?/)
            for label, values of @vertexLabels
                for v in values when typeof v is 'string'
                    @viz.registerVariable(v)
                done() if done?

    draw: (graph, frame = {}) ->
        # if there is a hidden graph, show it
        @showGraph() if @graphHidden
        # if we're in edit mode, @mode will be set already. otherwise, we need
        # to set it to "display"
        @mode ?= "display"
        @directed = graph.directed
        @inner.selectAll(".changed").classed("changed", null)
        @currentGraph = Vamonos.clone(graph)
        @currentFrame = Vamonos.clone(frame)
        if @persistentDragging
            @currentGraph.eachVertex (v) =>
                if @_savex[v.id]? and @_savey[v.id]?
                    v.x = @_savex[v.id]
                    v.y = @_savey[v.id]
        @updateVertices()
        @updateEdges()
        @startDragging()
        @previousGraph = graph

    clearDisplay: () ->
        @inner.remove()
        @inner = @initialize()

    # extranious force directed layout. doesn't save position
    forceIt: () ->
        width = @svg.node().offsetWidth
        height = @svg.node().offsetHeight
        ths = @
        trans = (d) -> "translate(" + [ d.x, d.y ] + ")"
        force = d3.layout.force()
            .charge(-300)
            .linkDistance(100)
            .size([width, height])
            .nodes(@currentGraph.getVertices())
            .links(@currentGraph.getEdges())
            .start()
        tick = () ->
            ths.inner.selectAll("g.vertex")
                .attr('transform', trans)
            ths.inner.selectAll("g.edge")
                .call(ths.genPath)
            ths.updateEdgeLabels()
        force.on("tick", tick)
        @inner.selectAll("g.vertex").call(force.drag)
        @forcedAlready = true


    startDragging: () ->
        console.log "startDragging" if window.DEBUG?
        trans = (d) -> "translate(" + [ d.x, d.y ] + ")"
        ths = @
        dragmove = (d) ->
            d.x = d3.event.x
            d.y = d3.event.y
            if ths.persistentDragging
                ths._savex[d.id] = d.x
                ths._savey[d.id] = d.y
            d3.select(this).attr('transform', trans)
            ths.inner.selectAll("g.edge")
                .call(ths.genPath)
            ths.updateEdgeLabels()
        drag = d3.behavior.drag()
            .on("drag", dragmove)
            .on "dragstart", () ->
                parent = this.parentNode
                ref = parent.querySelector(".graph-label")
                parent.insertBefore(this, ref)
        @inner.selectAll("g.vertex").call(drag)


    updateEdges: () ->
        console.log "updateEdges" if window.DEBUG?
        # update #
        edges = @inner.selectAll("g.edge")
            .data(@currentGraph.getEdges(),
                  @currentGraph.edgeId)
        edges.call(@genPath)
            .call(@updateEdgeClasses)
            .call(@updateEdgeStyles)

        # enter #
        # insert edges at the start of the svg, so they dont overlap
        # vertices, which are appended to the end of the svg
        enter = edges.enter()
            .insert("g", ":first-child")
            .attr("class", "edge")
        enter.append("path")
            .attr("class", "edge")
        enter.call(@genPath)
            .call(@updateEdgeClasses)
            .call(@updateEdgeStyles)
        # exit #
        edges.exit().remove()
        @updateEdgeLabels()

    # dispatches to genStraightPath or genCurvyPath depending on whether
    # edge `e` has a back-edge in `g`. sets _labelx and _labely on data.
    genPath: (sel) =>
        console.log "genPath" if window.DEBUG?
        getPath = (e) =>
            unless [e.source.x, e.source.y,
                    e.target.x, e.target.y].every(isFinite)
                throw "GETPATH: Bad coordinates"
            if not @directed
                path = @pathStraightNoArrow(e)
            else if @antiparallelEdge(e)
                path = @pathBezierWithArrow(e)
            else
                path = @pathStraightWithArrow(e)
            return path
        sel.selectAll("path.edge")
            .data((d) -> [d])           # update edge data for paths
            .attr("d", getPath)
            .attr("id", @currentGraph.edgeId)
        return sel

    antiparallelEdge: (e) =>
        return false unless @directed
        return @currentGraph.edge(e.target, e.source)

    # if the graph is not directed, there is no need to draw fancy
    # arrows. Just return a path from center of source vertex to
    # center of target vertex.
    pathStraightNoArrow: (e) =>
        midx = ( e.source.x + e.target.x ) / 2
        midy = ( e.source.y + e.target.y ) / 2
        [dx, dy] = @dvector([e.source.x,e.source.y], [e.target.x,e.target.y])
        [_, [lx,ly]] = @perpendicularPoints([midx,midy], dx, dy, @arrowWidth * 1.5)
        e._labelx = lx
        e._labely = ly
        return "M #{ e.source.x } #{ e.source.y } " +
               "L #{ e.target.x } #{ e.target.y } "

    # creates the text for the d attribute of a straight path element
    # representing an edge `e`.
    pathStraightWithArrow: (e) =>
        [x1,y1] = @intersectVertex([e.target.x, e.target.y],
                                   [e.source.x, e.source.y])
        return "M #{ e.source.x } #{ e.source.y }" +
                @pathArrowAt([x1,y1], [e.source.x, e.source.y], e)

    pathBezierWithArrow: (e) =>
        [refx, refy] = @bezierRefPoint(e)
        # get vertex intersection points
        [x1,y1] = @intersectVertex([e.source.x, e.source.y], [refx, refy])
        [x2,y2] = @intersectVertex([e.target.x, e.target.y], [refx, refy])
        return " M #{ e.source.x } #{ e.source.y } L #{ x1 } #{ y1 } " +
               " Q #{ refx } #{ refy } #{ x2 } #{ y2 }" +
               @pathArrowAt([x2, y2], [refx, refy], e)

    bezierRefPoint: (e) ->
        # midpoint of direct line from vertex center to vertex center
        # => (midx, midy)
        midx = (e.source.x + e.target.x) / 2
        midy = (e.source.y + e.target.y) / 2
        [dx, dy] = @dvector([e.source.x, e.source.y],
                            [e.target.x, e.target.y])
        # tangent point => (refx, refy)
        refx = midx - @bezierCurviness * dy
        refy = midy + @bezierCurviness * dx
        return [refx, refy]

    # arrow at (x1,y1) at the end of a line originating at (x2,y2). also sets
    # edge's _labelx and _labely if edge is present.
    pathArrowAt: ([x1,y1], [xstart,ystart], edge) ->
        [dx, dy] = @dvector([xstart,ystart], [x1,y1])
        # get stopping point before end of line
        x2 = x1 - (dx * -@arrowLength)
        y2 = y1 - (dy * -@arrowLength)
        [[x3,y3], [x4,y4]] = @perpendicularPoints([x2,y2], dx, dy, @arrowWidth / 2)
        if edge?
            [_, [x5,y5]] = @perpendicularPoints([x2,y2], dx,dy, @arrowWidth * 2)
            edge._labelx = x5
            edge._labely = y5
        return " L #{ x2 } #{ y2 } L #{ x3 } #{ y3 }" +
               " L #{ x1 } #{ y1 } L #{ x4 } #{ y4 }" +
               " L #{ x2 } #{ y2 } L #{ x1 } #{ y1 }"

    # gets [dx, dy] for the line defined by (x1,y1) and (x2,y2)
    dvector: ([x1,y1], [x2,y2]) =>
        dx = x1 - x2
        dy = y1 - y2
        dist = Math.sqrt(dx * dx + dy * dy)
        dx = dx / dist
        dy = dy / dist
        return [dx, dy]

    # get two points perpendicular to the line defined by (x,y) and dx
    # dy, at `len` distance.
    perpendicularPoints: ([x,y], dx, dy, len) =>
        return [[x + len * dy, y - len * dx],
                [x - len * dy, y + len * dx]]

    # get the point of intersection with the vertex centered at (x1,y1)
    intersectVertex: ([x1,y1], [x0,y0]) =>
        dx = x0 - x1
        dy = y0 - y1
        # abbreviation for squaring and floor
        sq = (x) -> Math.pow(x, 2)
        # do some algebra using the definition of ellipses
        a = @vertexWidth / 2 + 5
        b = @vertexHeight / 2 + 5
        thingy = a * b / Math.sqrt( sq(a) * sq(dy) + sq(b) * sq(dx) )
        return [thingy * dx + x1, thingy * dy + y1 ]

    updateVertices: () ->
        console.log "createVertices" if window.DEBUG?
        id = (vtx) -> return vtx.id
        trans = (d) -> "translate(" + [ d.x, d.y ] + ")"
        # update
        vertices = @inner.selectAll("g.vertex")
            .data(@currentGraph.getVertices(), id)
            .attr("transform", trans)
            .call(@updateVertexLabels)
            .call(@updateVertexClasses)
        # enter
        enter = vertices.enter()
            .append("g")
            .attr("transform", trans)
            .attr("class", "vertex")
        enter.append("ellipse")
            .attr("class", "vertex")
            .attr("cx", 0)
            .attr("cy", 0)
            .attr("rx", @vertexWidth  / 2)
            .attr("ry", @vertexHeight / 2)
        enter.call(@createVertexLabels)
            .call(@updateVertexClasses)
        # exit
        vertices.exit()
            .remove()

    # todo - use @currentGraph
    fitGraph: (graph, animate = false) ->
        console.log "fitGraph" if window.DEBUG?
        if graph?
            xVals = []
            yVals = []
            for vertex in graph.getVertices()
                xVals.push(vertex.x + (@vertexWidth  / 2) + @containerMargin * 2)
                yVals.push(vertex.y + (@vertexHeight / 2) + @containerMargin * 2)
            max_x = Math.max(xVals..., @minX)
            max_y = Math.max(yVals..., @minY)
        else
            max_x = 0
            max_y = 0
        if animate
            @$outer.animate({width: max_x, height: max_y}, 500)
        else
            @$outer.width(max_x)
            @$outer.height(max_y)
        if @resizable
            @$outer.resizable("option", "minWidth", max_x)
            @$outer.resizable("option", "minHeight", max_y)

    hideGraph: () ->
        @$outer.hide()
        @graphHidden = true

    showGraph: () ->
        @$outer.show()
        @graphHidden = false

    # ---------------------------------------------------------- #

    eachConnection: (f) ->
        return

    # ----------- display mode node functions ---------- #

    createVertexLabels: (vertexGroup) =>
        console.log "createVertexLabels" if window.DEBUG?
        x = @vertexWidth / 2
        y = @vertexHeight / 2
        xOffset = x / 2
        yOffset = y / 2
        setLabel = (klass, xPos, yPos) =>
            vertexGroup.append("text")
                .attr("class", klass)
                .attr("x", xPos)
                .attr("y", yPos)
        setLabel("vertex-contents", 0, yOffset / 2)
        setLabel("vertex-ne-label", x, - y)
        setLabel("vertex-nw-label", - x - xOffset, - y)
        setLabel("vertex-se-label", x, y + yOffset)
        setLabel("vertex-sw-label", - x - xOffset, y + yOffset)
        vertexGroup.call(@updateVertexLabels)
        return vertexGroup

    updateVertexLabels: (sel) =>
        console.log "updateVertexLabels #{ @mode }-mode" if window.DEBUG?
        for type, style of @vertexLabels
            target = sel.selectAll("text." + switch type
                when "inner" then "vertex-contents"
                when "ne"    then "vertex-ne-label"
                when "nw"    then "vertex-nw-label"
                when "se"    then "vertex-se-label"
                when "sw"    then "vertex-sw-label"
                else
                    throw Error "GraphDisplay '#{ @varName }': no vertex label \"#{ type }\""
            )
            target.data((d) -> [d])
            if style.constructor.name is "Function"
                target.html((d) => Vamonos.rawToTxt(style(d)))
            else if style.constructor.name is "Array"
                target.html (d) =>
                    res = []
                    for v in style when @currentFrame[v]?.id is d.id
                        res.push(Vamonos.resolveSubscript(Vamonos.removeNamespace(v)))
                    return res.join(",")
            else if (style.constructor.name is "Object" and
                     style[@mode]?.constructor.name is "Function")
                target.html((d) => Vamonos.rawToTxt(style[@mode](d)))
            else
                target.text("")
        return sel

    createEdgeLabels: () =>
        return unless @edgeLabel[@mode]?
        console.log "createEdgeLabels" if window.DEBUG?
        @inner.selectAll("text.graph-label")
            .data((d)->@currentGraph.getEdges())
            .enter()
            .append("text")
            .attr("class", "graph-label")
        @updateEdgeLabels()
        return edgeGroups

    updateEdgeLabels: () =>
        return unless @edgeLabel[@mode]?
        console.log "updateEdgeLabels" if window.DEBUG?
        sel = @inner.selectAll("text.graph-label")
            .data((d)=>@currentGraph.getEdges())
            .text(@edgeLabelVal)
            .attr("x", (d)->d._labelx)
            .attr("y", (d)->d._labely)
        sel.enter()
            .append("text")
            .attr("class", "graph-label")
            .text(@edgeLabelVal)
            .attr("x", (d)->d._labelx)
            .attr("y", (d)->d._labely)
        sel.exit()
            .remove()

    setEdgeLabelPos: (labelSel) =>
        xPos = (e) =>
            if @antiparallelEdge(e)
                [x,y] = @bezierRefPoint(e)
                return x
            else
                return Math.floor((e.source.x + e.target.x) / 2)
        yPos = (e) =>
            if @antiparallelEdge(e)
                [x,y] = @bezierRefPoint(e)
                return y + 4
            else
                return Math.floor((e.source.y + e.target.y) / 2 + 4)

        labelSel.attr("x", xPos)
                .attr("y", yPos)

    edgeLabelVal: (edge) =>
        return unless @edgeLabel[@mode]?
        if @edgeLabel[@mode].constructor.name is 'Function'
            val = @edgeLabel[@mode](edge)
        else if @edgeLabel[@mode].constructor.name is 'String'
            attr = @edgeLabel[@mode]
            val = Vamonos.rawToTxt(edge[attr] ? "")
        else
            return

    updateEdgeClasses: (edgeGroups) =>
        return unless @edgeCssAttributes?
        console.log "updateEdgeClasses" if window.DEBUG?
        lines = edgeGroups.selectAll("path.edge")
            .data((d)->[d])
        for klass, test of @edgeCssAttributes
            if test?.constructor.name is 'Function'
                lines.classed(klass, test)
            else if test?.constructor.name is 'String'
                if test.match(/<->/) # bidirectional
                    [source, target] = test.split(/<->/).map((v) => @currentFrame[v])
                    lines.classed(klass, (e) ->
                        (e.source.id == source?.id and e.target.id == target?.id) or
                        (e.target.id == source?.id and e.source.id == target?.id))
                else
                    [source, target] = test.split(/->/).map((v) => @currentFrame[v])
                    lines.classed(klass, (e) -> e.source.id == source?.id and
                                                e.target.id == target?.id)
        return edgeGroups

    updateEdgeStyles: (edgeGroups) =>
        return unless @styleEdges?.length
        for styleFunc in @styleEdges
            continue unless styleFunc.constructor.name is 'Function'
            styles = (@appliedEdgeStyles ?= [])
            edgeGroups.selectAll("path.edge")
                .data((d)->[d])
                .each (e) ->
                    res = styleFunc(e)
                    if res?.length == 2
                        [attr, val] = res
                        styles.push attr
                        d3.select(this).style(attr, val)
                    else
                        d3.select(this).style(attr, null) for attr in styles

    # this will be cleaner should I find a way to have ellipses and
    # text svg elements inherit classes from their groups. otherwise
    # we need to tell both ellipses and vertex-content text elems what
    # their class is, so they can color coordinate (like black oval
    # with white text).
    updateVertexClasses: (vertexGroups) =>
        console.log "updateVertexClasses" if window.DEBUG?

        vertices = vertexGroups.selectAll("ellipse.vertex")
            .data((d) -> [d])
            .classed("changed", (vertex) =>
                return @highlightChanges and
                       @mode is 'display' and
                       @vertexChanged(vertex)
            )

        labels = vertexGroups.selectAll("text.vertex-contents")
            .data((d) -> [d])

        for attr, val of @vertexCssAttributes
            if val.constructor.name is "Function"
                ths = @
                vertexGroups.each (vertex) ->
                    (ths.appliedNodeClasses ?= {})[vertex.id] ?= {}
                    sel = d3.select(this)
                    newClass = val(vertex)
                    # dont reapply classes
                    return if newClass is ths.appliedNodeClasses[vertex.id][attr]
                    # remove previously applied class for this attr
                    if ths.appliedNodeClasses[vertex.id][attr]?
                        sel.select("ellipse.vertex")
                            .classed(ths.appliedNodeClasses[vertex.id][attr], false)
                        sel.select("text.vertex-contents")
                            .classed(ths.appliedNodeClasses[vertex.id][attr], false)
                    # add new class
                    if newClass?
                        sel.select("ellipse.vertex").classed(newClass, true)
                        sel.select("text.vertex-contents").classed(newClass, true)
                        ths.appliedNodeClasses[vertex.id][attr] = newClass
                    else
                        delete ths.appliedNodeClasses[vertex.id][attr]

            else if val.constructor.name is "Array"
                for kind in val
                    applyClass = (sel) ->
                        sel.classed("#{ attr }-#{ kind }", (vtx) -> vtx[attr] == kind )
                    vertices.call(applyClass)
                    labels.call(applyClass)

            else
                vertices.classed(attr, (vertex) -> vertex[attr] == val)

    vertexChanged: (newv) ->
        return false unless newv?
        return false unless @previousGraph?
        return false unless oldv = @previousGraph.vertex(newv.id)
        for k,v of newv when k[0] isnt "_"
            if v?.type is "Vertex"
                return true if oldv[k]?.id isnt v.id
            else
                return true if oldv[k] isnt v
        for k,v of oldv when k[0] isnt "_"
            if v?.type is "Vertex"
                return true if newv[k]?.id isnt v.id
            else
                return true if newv[k] isnt v

    # ----------------- drawer --------------- #

    openDrawer: ({buttons, label}) ->
        if @$drawer?
            @$drawer.html("<div class='graph-drawer'></div>")
        else
            @$drawer = $("<div>", { class: "graph-drawer" }).hide()
            @$outer.after(@$drawer)
        $("<span class='label'>#{label}</span>").appendTo(@$drawer)
        @$drawer.append(buttons) if buttons?
        @$drawer.fadeIn("fast") unless @$drawer.is(":visible")

    closeDrawer: ->
        return unless @$drawer?
        @$drawer.fadeOut("fast")

    # ----------- styles, colors and jsplumb stuff -------------- #

    @editColor        = "#92E894"
    @lightEdgeColor   = "#cccccc"
    @darkEdgeColor    = "#aaaaaa"
    @deletionColor    = "#FF7D7D"
    @lineWidth        = 4

    normalPaintStyle:
        dashstyle   : "0"
        lineWidth   : @lineWidth
        strokeStyle : @lightEdgeColor

    potentialEdgePaintStyle:
        dashstyle   : "1 1"
        strokeStyle : @editColor
        lineWidth   : @lineWidth + 1

    selectedPaintStyle:
        lineWidth   : @lineWidth
        strokeStyle : @editColor

    hoverPaintStyle:
        lineWidth   : @lineWidth
        strokeStyle : @darkEdgeColor

    customStyle: (color, width) ->
        lineWidth   : width ? GraphDisplay.lineWidth
        strokeStyle : color

@Vamonos.export { Widget: { GraphDisplay } }
