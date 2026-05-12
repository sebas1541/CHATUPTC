import Foundation

/// Unidad atómica de la base de conocimiento (programa o doc de análisis).
/// Cada doc se embebe y se recupera independientemente.
public struct KnowledgeDoc: Sendable, Identifiable {
    public enum Kind: String, Sendable { case program, analysis }

    public let id: String
    public let kind: Kind
    public let title: String
    /// Texto formateado para inyectar al prompt del LLM.
    public let promptBody: String
    /// Texto plano para embedding (sin markdown ni etiquetas).
    public let embeddingText: String
}

public enum Knowledge {

    // MARK: System prompt (con retrieval)

    /// Construye el system prompt usando solo los docs recuperados.
    /// Si `docs` está vacío, cae a un prompt genérico (sin contexto).
    public static func systemPrompt(usingDocs docs: [KnowledgeDoc]) -> String {
        let context: String
        if docs.isEmpty {
            context = "(No se encontró información relevante en el catálogo. Responde de manera honesta diciendo que la información no está disponible y sugiere verificar en uptc.edu.co.)"
        } else {
            context = docs.map(\.promptBody).joined(separator: "\n\n---\n\n")
        }

        return """
        Eres UPTCBot, un asistente NO oficial especializado en programas de pregrado \
        presenciales de la Universidad Pedagógica y Tecnológica de Colombia (UPTC) en \
        la sede central Tunja.

        Reglas de comportamiento:
        1. Responde en español, conciso y bien estructurado.
        2. Usa SOLO la información de los documentos recuperados que aparecen abajo.
        3. Si el dato pedido no está en los documentos, dilo explícitamente: "La \
           información no está en mi base de conocimiento. Verifica en uptc.edu.co."
        4. Para recomendaciones presenta una opción principal y una o dos \
           complementarias, justificando brevemente cada una.
        5. Nunca inventes códigos SNIES, créditos, duraciones, costos, requisitos o \
           fechas.
        6. Eres asistente no oficial. Para trámites, costos o información sensible, \
           sugiere verificar en uptc.edu.co.

        ===== DOCUMENTOS RECUPERADOS PARA ESTA CONSULTA =====

        \(context)

        ===== FIN =====
        """
    }

    // MARK: Cargar todos los docs

    /// Devuelve los 54 docs unificados (32 programas + 22 análisis).
    public static func allDocs() throws -> [KnowledgeDoc] {
        let programs = try loadJSONArray(name: "programas_uptc").map(programDoc)
        let analyses = try loadJSONArray(name: "analysis_docs").map(analysisDoc)
        return programs + analyses
    }

    // MARK: Helpers

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

    private static func programDoc(_ p: [String: Any]) -> KnowledgeDoc {
        let nombre = string(p["programa"])
        let facultad = string(p["facultad"])
        let sede = string(p["sede"])

        var promptLines: [String] = []
        promptLines.append("### \(nombre)")
        promptLines.append("Facultad: \(facultad)")
        promptLines.append("Sede: \(sede)")
        if let v = nonEmpty(p["titulo"]) { promptLines.append("Título: \(v)") }
        if let v = nonEmpty(p["duracion"]) { promptLines.append("Duración: \(v)") }
        if let v = nonEmpty(p["creditos"]) { promptLines.append("Créditos: \(v)") }
        if let v = nonEmpty(p["modalidad"]) { promptLines.append("Modalidad: \(v)") }
        if let v = nonEmpty(p["snies"]) { promptLines.append("SNIES: \(v)") }
        if let v = nonEmpty(p["perfil_profesional"]) {
            promptLines.append("Perfil profesional: \(v)")
        }
        if let v = nonEmpty(p["perfil_ocupacional"]) {
            promptLines.append("Perfil ocupacional: \(v)")
        }
        if let arr = p["campos_laborales"] as? [String], !arr.isEmpty {
            promptLines.append("Campos laborales: \(arr.joined(separator: "; "))")
        }
        if let arr = p["areas"] as? [String], !arr.isEmpty {
            promptLines.append("Áreas: \(arr.joined(separator: "; "))")
        }
        if let arr = p["habilidades"] as? [String], !arr.isEmpty {
            promptLines.append("Habilidades: \(arr.joined(separator: "; "))")
        }
        if let arr = p["materias_clave"] as? [String], !arr.isEmpty {
            promptLines.append("Materias clave: \(arr.joined(separator: "; "))")
        }
        if let v = nonEmpty(p["descripcion_extensa"]) {
            promptLines.append("Descripción: \(v)")
        }

        // Embedding: solo texto plano relevante, sin markdown ni etiquetas
        var embedLines: [String] = [nombre, facultad]
        if let v = nonEmpty(p["descripcion_extensa"]) { embedLines.append(v) }
        if let v = nonEmpty(p["perfil_profesional"]) { embedLines.append(v) }
        if let arr = p["areas"] as? [String] { embedLines.append(contentsOf: arr) }
        if let arr = p["materias_clave"] as? [String] { embedLines.append(contentsOf: arr) }
        if let arr = p["campos_laborales"] as? [String] { embedLines.append(contentsOf: arr) }

        return KnowledgeDoc(
            id: "program:\(nombre)",
            kind: .program,
            title: nombre,
            promptBody: promptLines.joined(separator: "\n"),
            embeddingText: embedLines.joined(separator: " ")
        )
    }

    private static func analysisDoc(_ d: [String: Any]) -> KnowledgeDoc {
        let id = string(d["id"])
        let tema = string(d["tema"])
        let contenido = string(d["contenido"])
        return KnowledgeDoc(
            id: "analysis:\(id)",
            kind: .analysis,
            title: tema,
            promptBody: "### \(tema)\n\(contenido)",
            embeddingText: "\(tema). \(contenido)"
        )
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
