import Foundation

public enum Knowledge {
    public static func systemPrompt() throws -> String {
        let context = try loadContext()
        return """
        Eres UPTCBot, un asistente NO oficial especializado en programas de pregrado \
        presenciales de la Universidad Pedagógica y Tecnológica de Colombia (UPTC) en \
        la sede central Tunja. Tu fuente única es la base de conocimiento que aparece \
        abajo, dividida en dos partes: (1) un CATÁLOGO con datos por programa, y (2) \
        DOCUMENTOS DE ANÁLISIS Y RECOMENDACIONES que comparan programas por afinidad, \
        similitud y perfil de interés.

        Reglas de comportamiento:
        1. Responde siempre en español, de forma concisa, clara y bien estructurada.
        2. Para preguntas sobre un programa específico (créditos, SNIES, perfil, \
           materias, modalidad, duración) consulta primero el CATÁLOGO. Si el dato no \
           está, dilo explícitamente: "La base de conocimiento no incluye ese dato \
           para este programa. Verifica en uptc.edu.co."
        3. Para preguntas comparativas o de recomendación ("qué programa me \
           recomiendas si...", "qué programa se parece a...", "cuál tiene más \
           matemáticas...") usa los DOCUMENTOS DE ANÁLISIS, combinando con el catálogo.
        4. Cuando recomiendes programas, presenta una opción principal y una o dos \
           complementarias, justificando brevemente cada una.
        5. Nunca inventes datos: códigos SNIES, créditos, duraciones, costos, \
           requisitos de admisión o fechas. Si no están en la base, di que no los \
           tienes.
        6. Eres un asistente no oficial. Para trámites o información sensible, \
           siempre sugiere verificar en uptc.edu.co o canales oficiales de la UPTC.
        7. No cites URLs de la base de conocimiento al usuario; si necesitas dirigir a \
           una fuente, usa solo uptc.edu.co.

        ===== BASE DE CONOCIMIENTO =====

        \(context)

        ===== FIN DE BASE DE CONOCIMIENTO =====
        """
    }

    public static func loadContext() throws -> String {
        let programs = try loadJSONArray(name: "programas_uptc")
        let analyses = try loadJSONArray(name: "analysis_docs")
        let programsSection = """
        ## CATÁLOGO DE PROGRAMAS

        \(programs.map(formatProgram).joined(separator: "\n\n---\n\n"))
        """
        let analysisSection = """
        ## DOCUMENTOS DE ANÁLISIS Y RECOMENDACIONES

        \(analyses.map(formatAnalysisDoc).joined(separator: "\n\n---\n\n"))
        """
        return programsSection + "\n\n========\n\n" + analysisSection
    }

    private static func loadJSONArray(name: String) throws -> [[String: Any]] {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            throw KnowledgeError.resourceMissing("\(name).json")
        }
        let data = try Data(contentsOf: url)
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw KnowledgeError.malformedJSON("\(name).json")
        }
        return arr
    }

    private static func formatProgram(_ p: [String: Any]) -> String {
        var lines: [String] = []
        lines.append("### \(string(p["programa"]))")
        lines.append("Facultad: \(string(p["facultad"]))")
        lines.append("Sede: \(string(p["sede"]))")
        if let v = nonEmpty(p["duracion"]) { lines.append("Duración: \(v)") }
        if let v = nonEmpty(p["modalidad"]) { lines.append("Modalidad: \(v)") }
        if let v = nonEmpty(p["snies"]) { lines.append("SNIES: \(v)") }
        if let v = nonEmpty(p["perfil_profesional"]) { lines.append("Perfil profesional: \(v)") }
        if let v = nonEmpty(p["perfil_ocupacional"]) { lines.append("Perfil ocupacional: \(v)") }
        if let arr = p["campos_laborales"] as? [String], !arr.isEmpty {
            lines.append("Campos laborales: \(arr.joined(separator: "; "))")
        }
        if let arr = p["areas"] as? [String], !arr.isEmpty {
            lines.append("Áreas: \(arr.joined(separator: "; "))")
        }
        if let arr = p["habilidades"] as? [String], !arr.isEmpty {
            lines.append("Habilidades: \(arr.joined(separator: "; "))")
        }
        if let arr = p["materias_clave"] as? [String], !arr.isEmpty {
            lines.append("Materias clave: \(arr.joined(separator: "; "))")
        }
        if let v = nonEmpty(p["descripcion_extensa"]) { lines.append("Descripción: \(v)") }
        return lines.joined(separator: "\n")
    }

    private static func formatAnalysisDoc(_ d: [String: Any]) -> String {
        "### \(string(d["tema"]))\n\(string(d["contenido"]))"
    }

    private static func string(_ v: Any?) -> String { (v as? String) ?? "" }

    private static func nonEmpty(_ v: Any?) -> String? {
        guard let s = v as? String, !s.isEmpty else { return nil }
        return s
    }
}

public enum KnowledgeError: Error, CustomStringConvertible {
    case resourceMissing(String)
    case malformedJSON(String)

    public var description: String {
        switch self {
        case .resourceMissing(let f): "Recurso no encontrado: \(f)"
        case .malformedJSON(let f): "JSON mal formado: \(f)"
        }
    }
}
